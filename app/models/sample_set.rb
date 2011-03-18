class SampleSet < ActiveRecord::Base
  has_many :chips
  accepts_nested_attributes_for :chips

  belongs_to :chip_type
  belongs_to :project
  belongs_to :naming_scheme
  belongs_to :service_option
  validates_associated :chip_type, :project, :service_option

  validates_presence_of :submission_date, :submitted_by, :chip_type_id, :project_id

  after_create :check_chip_inventory, :send_facility_notification, :send_approval_request

  attr_accessor :number

  #validate :at_least_one_sample

  def self.parse_api(attributes)
    # remove attributes that aren't stored
    ["next_step"].each{|key| attributes.delete(key)}

    sample_set = SampleSet.new(attributes)
    
    return sample_set
  end

  def error_message
    messages = errors.full_messages

    samples.each do |sample|
      if sample.valid?
        sample.errors.each do |error|
          messages << "#{error[0].humanize} #{error[1]}"
        end
      else
        sample.errors.each do |error|
          messages << "#{error[0].humanize} #{error[1]}"
        end 
      end
    end

    message = messages.uniq.join(", ")

    return message
  end
  
  def ready_yes_or_no
    ready_for_processing ? "Yes" : "No"
  end

  def samples
    Sample.find(:all, :include => {:microarray => :chip}, :conditions => ["chips.sample_set_id = ?", id])
  end

  def name
    "#{user && user.full_name || submitted_by} - #{chip_type.name} (#{chips.size} Chips/Slides)"
  end

  def user
    submitted_by_id && User.find(submitted_by_id)
  end

  private

  def sample_specific_attributes
    return attribute_subset([
      "submission_date", "project_id", "sbeams_user", "chip_type_id", "service_option_id",
        "naming_scheme_id"
    ])
  end

  def self.hash_values_sorted_by_keys(hash)
    hash.sort.collect{|element| element[1]}
  end

  def self.parse_multi_field_date(attributes)
    return unless attributes

    # assume multi-field if year field is present
    if attributes["date(1i)"]
      return Date.new(
        attributes.delete("date(1i)").to_i,
        attributes.delete("date(2i)").to_i,
        attributes.delete("date(3i)").to_i
      )
    end
  end

  #def at_least_one_sample
  #  errors.add(:samples, "must be provided") unless samples.size >= 1
  #end

#  # use validatable gem since we're validating attributes that aren't fields
#  # in the sample_sets table (because they're transient)
#  include Validatable
#
#  attr_accessor :submission_date, :number_of_samples, :project_id, :naming_scheme_id, :integer,
#    :chip_type_id, :sbeams_user, :label_id, :service_option_id
#
#  validates_numericality_of :number_of_samples
#  validates_presence_of :chip_type_id, :project_id, :service_option_id
#  
#  has_many :samples
#  
#  after_create :check_chip_inventory, :send_facility_notification, :send_approval_request
#
#  def self.new(attributes=nil)
#    parse_multi_field_date(attributes)
#    convert_to_integers(attributes)
#
#    sample_set = super
#      
#    # set the default label
#    if attributes && attributes[:chip_type_id] && attributes[:chip_type_id] != ""
#      sample_set.label_id = ChipType.find(attributes[:chip_type_id]).platform.default_label_id
#    end
#
#    return sample_set
#  end
#
#  def project
#    Project.find_by_id(project_id)
#  end
#
#  def chip_type
#    ChipType.find_by_id(chip_type_id)
#  end
#
#  def platform
#    return chip_type.platform
#  end
#
#  def naming_scheme
#    NamingScheme.find_by_id(naming_scheme_id)
#  end
#
#  def self.parse_multi_field_date(attributes)
#    return unless attributes
#
#    # assume multi-field if year field is present
#    if attributes["submission_date(1i)"]
#      attributes["submission_date"] = Date.new(
#        attributes.delete("submission_date(1i)").to_i,
#        attributes.delete("submission_date(2i)").to_i,
#        attributes.delete("submission_date(3i)").to_i
#      )
#    end
#  end
#
#  def self.convert_to_integers(attributes)
#    return unless attributes
#
#    attributes.each do |key, value|
#      attributes[key] = Integer(value) rescue value
#    end
#  end

  def check_chip_inventory
    return if chips.empty?

    chips_needed = chips.size
    available = chip_type.total_inventory

    if available - chips_needed < 0
      Notifier.deliver_low_inventory_notification(chip_type.name, chips_needed, available)
    end
  end

#  def service_option
#    ServiceOption.find_by_id(service_option_id)
#  end
#
  def cost_estimate
    number.to_i * service_option.total_cost
  end

  def send_facility_notification
    return if chips.empty?

    Notifier.deliver_sample_submission_notification(self)
  end

  def send_approval_request
    return if chips.empty?

    lab_group = project.lab_group

    if needs_investigator_approval?
      investigator_emails = UserProfile.investigators(lab_group).collect{|i| i.user.email}
      Notifier.deliver_approval_request(samples, investigator_emails)
    elsif needs_manager_approval? 
      manager_emails = UserProfile.managers(lab_group).collect{|i| i.user.email}
      Notifier.deliver_approval_request(samples, manager_emails)
    end  
  end

  def needs_investigator_approval?
    lab_group_profile = project.lab_group.lab_group_profile
    lab_group_profile.require_investigator_approval && cost_estimate >= lab_group_profile.investigator_approval_minimum
  end

  def needs_manager_approval?
    lab_group_profile = project.lab_group.lab_group_profile
    lab_group_profile.require_manager_approval && cost_estimate >= lab_group_profile.manager_approval_minimum
  end

  def needs_approval?
    if needs_investigator_approval? || needs_manager_approval?
      true
    else
      false
    end
  end
end
