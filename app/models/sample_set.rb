class SampleSet < ActiveRecord::Base
  # use validatable gem since we're validating attributes that aren't fields
  # in the sample_sets table (because they're transient)
  include Validatable

  attr_accessor :submission_date, :number_of_samples, :project_id, :naming_scheme_id, :integer,
    :chip_type_id, :sbeams_user, :label_id, :service_option_id

  validates_numericality_of :number_of_samples
  validates_presence_of :chip_type_id, :project_id, :service_option_id
  
  has_many :samples
  
  after_create :check_chip_inventory, :send_facility_notification, :send_approval_request

  def self.new(attributes=nil)
    parse_multi_field_date(attributes)
    convert_to_integers(attributes)

    sample_set = super
      
    # set the default label
    if attributes && attributes[:chip_type_id] && attributes[:chip_type_id] != ""
      sample_set.label_id = ChipType.find(attributes[:chip_type_id]).platform.default_label_id
    end

    return sample_set
  end

  def project
    Project.find_by_id(project_id)
  end

  def chip_type
    ChipType.find_by_id(chip_type_id)
  end

  def platform
    return chip_type.platform
  end

  def naming_scheme
    NamingScheme.find_by_id(naming_scheme_id)
  end

  def self.parse_multi_field_date(attributes)
    return unless attributes

    # assume multi-field if year field is present
    if attributes["submission_date(1i)"]
      attributes["submission_date"] = Date.new(
        attributes.delete("submission_date(1i)").to_i,
        attributes.delete("submission_date(2i)").to_i,
        attributes.delete("submission_date(3i)").to_i
      )
    end
  end

  def self.convert_to_integers(attributes)
    return unless attributes

    attributes.each do |key, value|
      attributes[key] = Integer(value) rescue value
    end
  end

  def check_chip_inventory
    chips_needed = (number_of_samples.to_f / chip_type.arrays_per_chip).ceil
    available = chip_type.total_inventory

    if available - chips_needed < 0
      Notifier.deliver_low_inventory_notification(chip_type.name, chips_needed, available)
    end
  end

  def service_option
    ServiceOption.find_by_id(service_option_id)
  end

  def cost_estimate
    number_of_samples * service_option.total_cost
  end

  def send_facility_notification
    Notifier.deliver_sample_submission_notification(samples)
  end

  def send_approval_request
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
