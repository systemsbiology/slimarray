class SampleSet < ActiveRecord::Base
  has_many :chips

  belongs_to :chip_type
  belongs_to :project
  belongs_to :naming_scheme
  belongs_to :service_option
  validates_associated :chip_type, :project, :service_option

  validates_presence_of :submission_date, :submitted_by, :chip_type_id, :project_id

  after_create :check_chip_inventory, :send_facility_notification, :send_approval_request, :record_chip_transactions,
    :mark_as_hybridized

  attr_accessor :number, :already_hybridized

  def chips_attributes=(attributes)
    attributes.sort.each do |key, chip_attributes|
      chip = chips.build(chip_attributes.merge(:sample_set => self))
    end
  end

  def self.parse_api(attributes)
    # remove attributes that aren't stored
    attributes.delete("next_step")

    # find the user
    user = User.find_by_login(attributes["submitted_by"])
    attributes["submitted_by_id"] = user.id if user

    sample_set = SampleSet.new(attributes)
    
    return sample_set
  end

  def record_chip_transactions
    if already_hybridized == "1"
      Chip.record_chip_transactions(chips)
    end
  end

  def mark_as_hybridized
    if already_hybridized == "1"
      chips.each{|chip| chip.hybridize!}
    end
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
    "#{user && user.full_name || submitted_by} - #{chip_type.platform_and_name} (#{chips.size} Chips/Slides)"
  end

  def user(options = {:cached => true})
    if options[:cached]
      @@all_users_by_id ||= User.all_by_id

      return submitted_by_id && @@all_users_by_id[submitted_by_id]
    else
      return submitted_by_id && User.find(submitted_by_id)
    end
  end

  def self.accessible_to_user_with_status(user, status)
    lab_group_ids = user.get_lab_group_ids

    SampleSet.find(:all, :include => [:project, :chips],
      :conditions => ["projects.lab_group_id IN (?) AND chips.status = ?", lab_group_ids, status])
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

  def check_chip_inventory
    return if chips.empty?

    chips_needed = chips.size
    available = chip_type.total_inventory

    if available - chips_needed < 0
      Notifier.deliver_low_inventory_notification(chip_type.name, chips_needed, available)
    end
  end

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
