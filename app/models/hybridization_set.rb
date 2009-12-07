class HybridizationSet
  # ActiveRecord-style validations
  include Validatable

  attr_accessor :previous_step
  attr_accessor :date
  attr_accessor :platform_id
  attr_accessor :number_of_arrays
  attr_accessor :number_of_channels
  attr_accessor :charge_template_id
  attr_accessor :chip_type_id
  attr_accessor :sample_ids
  attr_accessor :chip_names
  attr_accessor :hybridizations
  attr_accessor :array_entry_errors

  # step 1 validations
  validates_presence_of :date, :groups => :step1
  validates_numericality_of :platform_id, :message => "must be selected",
    :groups => [:step1, :step2_no_multi_arrays, :step2_with_multi_arrays,
    :step3_no_multi_arrays, :step3_with_multi_arrays]

  # step 2 validations
  validates_numericality_of :charge_template_id,
    :message => "must be selected",
    :groups => [:step2_no_multi_arrays, :step2_with_multi_arrays,
                :step3_no_multi_arrays, :step3_with_multi_arrays]
  validates_numericality_of :number_of_arrays,
    :message => "must be entered",
    :groups => [:step2_no_multi_arrays, :step2_with_multi_arrays,
                :step3_no_multi_arrays, :step3_with_multi_arrays]
  validates_numericality_of :number_of_channels,
    :message => "must be entered",
    :groups => [:step2_no_multi_arrays, :step2_with_multi_arrays,
                :step3_no_multi_arrays, :step3_with_multi_arrays]
  validates_numericality_of :chip_type_id,
    :message => "must be selected",
    :groups => [:step2_with_multi_arrays, :step3_with_multi_arrays]

  # initialize accepts an option hash with the following parameters:
  #
  # * <tt>previous_step</tt> - The name of the last step the user was on
  # * <tt>date</tt> - The date of the hybridization(s)
  # * <tt>platform_id</tt> - The platform that's going to be used
  # * <tt>number_of_arrays</tt> - Number of samples that will be hybridized
  # * <tt>number_of_channels</tt> - Number of channels per array
  # * <tt>charge_template_id</tt> - The charge template to base the charges on
  # * <tt>chip_type_id</tt> - The chip type being used, only necessary for multi-arrays
  # * <tt>sample_ids</tt> - sample ids being used
  # * <tt>chip_names</tt> - user specified names for the chips, only used if chip numbering is off
  def initialize(options = {})
    options ||= {}
    @previous_step = options[:previous_step]
    @date = parse_date(options) || Date.today
    @platform_id = integer_or_nil(options[:platform_id])
    @number_of_arrays = integer_or_nil(options[:number_of_arrays])
    @number_of_channels = integer_or_nil(options[:number_of_channels])
    @charge_template_id = integer_or_nil(options[:charge_template_id])
    @chip_type_id = integer_or_nil(options[:chip_type_id])
    @sample_ids = options[:sample_ids]
    @chip_names = options[:chip_names]
  end

  def step
    if previous_step.nil? || previous_step == ""
      # no previous step means we're on step 1 and shouldn't show any errors
      "step1"
    elsif valid_for_step2_with_multi_arrays?
      # don't check validity of fields if user just came from step 2
      valid_for_step3_with_multi_arrays? unless previous_step == "step2_with_multi_arrays"
      "step3_with_multi_arrays"
    elsif valid_for_step2_no_multi_arrays?
      # don't check validity of fields if user just came from step 2
      valid_for_step3_no_multi_arrays? unless previous_step == "step2_no_multi_arrays"
      "step3_no_multi_arrays"
    elsif valid_for_step1? && multi_arrays
      # don't check validity of fields if user just came from step 1
      valid_for_step2_with_multi_arrays? unless previous_step == "step1"
      "step2_with_multi_arrays"
    elsif valid_for_step1? && !multi_arrays
      # don't check validity of fields if user just came from step 1
      valid_for_step2_no_multi_arrays? unless previous_step == "step1"
      "step2_no_multi_arrays"
    else
      "step1"
    end
  end

  def platform
    @platform ||= Platform.find(@platform_id) rescue nil
  end

  def chip_type
    @chip_type ||= ChipType.find(@chip_type_id) rescue nil
  end

  def multi_arrays
    return platform && platform.has_multi_array_chips
  end

  def multiple_labels
    return platform && platform.multiple_labels
  end

  def number_of_chips
    (number_of_arrays.to_f/chip_type.arrays_per_chip).ceil
  end

  def save
    return false unless
      (valid_for_step1? && valid_for_step2_with_multi_arrays? && array_entries_complete?) ||
      (valid_for_step1? && valid_for_step2_no_multi_arrays? && array_entries_complete?)

    self.hybridizations = Array.new

    return false if duplicate_samples_specified

    current_chip_number = 1
    begin
      Hybridization.transaction do
        sample_ids.each do |chip_index, chip_samples|
          # use the chip names the user provided, or if there are none use the chip number
          if(chip_names)
            chip_name = chip_names.shift
          else
            chip_name = name_for_date_and_chip_number(date, current_chip_number)
          end

          # with multi arrays
          if multi_arrays

          # no multi arrays
          else
            chip = Chip.create!(:name => chip_name)
            microarray = Microarray.create!(:chip_id => chip.id, :array_number => 1)
            hybridization = Hybridization.create!(
              :hybridization_date => date,
              :chip_number => current_chip_number,
              :microarray_id => microarray.id,
              :charge_template_id => charge_template_id
            )

            chip_samples.each do |channel_index, sample_id|
              sample = Sample.find(sample_id)
              sample.update_attributes(:hybridization_id => hybridization.id)
            end

            self.hybridizations << hybridization
          end

          current_chip_number += 1
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      case e.to_s
      when /duplicate/i
        self.array_entry_errors = "One or more of these chip numbers have already been used for this date: " +
          date
      when 
        self.array_entry_errors = "Something went horribly wrong. Check with your SLIMarray" +
          " administrator on this one."
      end
      return false
    end

    Hybridization.record_charges(hybridizations) if SiteConfig.track_charges?
    Hybridization.record_as_chip_transactions(hybridizations) if SiteConfig.track_inventory?

    return true
  end

  def array_entries_complete?
    case multi_arrays
    when true
      false
    when false
      sample_ids
    end
  end

  # samples that are available to hybridize for the current platform
  def available_samples
    @available_samples ||= Sample.find(
      :all,
      :include => :chip_type,
      :conditions => "status = 'submitted' AND chip_types.platform_id = #{platform.id}"
    )
  end

  # chip types for the current platform
  def chip_types
    @chip_types ||= ChipType.find(
      :all,
      :conditions => {:platform_id => platform.id}
    )
  end

#  def hybridizations(options = {})
#    current_hyb_number = options[:last_hyb_number]
#    available_samples = options[:available_samples]
#
#    samples = Array.new
#    if selected_samples != nil
#      for sample in available_samples
#        if selected_samples[sample.id.to_s] == '1'
#          samples << Sample.find(sample.id)
#        end
#      end
#    end
#
#
#    for sample in samples
#      project = sample.project
#      # does user want charge set(s) created based on projects?
#      if(@charge_set_id == "-1")
#        # get latest charge period
#        charge_period = ChargePeriod.find(:first, :order => "name DESC")
#
#        # if no charge periods exist, make a default one
#        if( charge_period == nil )
#          charge_period = ChargePeriod.new(:name => "Default Charge Period")
#          charge_period.save
#        end
#        
#        charge_set = ChargeSet.find(:first, :conditions => ["name = ? AND lab_group_id = ? AND budget = ? AND charge_period_id = ?",
#                                     project.name, project.lab_group_id, project.budget, charge_period.id])
#
#        # see if new charge set need to be created
#        if(charge_set == nil)
#          charge_set = ChargeSet.new(:charge_period_id => charge_period.id,
#                                      :name => project.name,
#                                      :lab_group_id => project.lab_group_id,
#                                      :budget => project.budget
#                                      )
#          charge_set.save
#        end
#        
#        @charge_set_id = charge_set.id
#      end
#
#      current_hyb_number += 1
#      @hybridizations << Hybridization.new(:hybridization_date => date,
#            :chip_number => current_hyb_number,
#            :charge_set_id => @charge_set_id,
#            :charge_template_id => charge_template_id,
#            :sample_id => sample.id)
#    end
#
#    return @hybridizations
#  end
#
#  def number
#    @hybridizations.size
#  end

  private

  def integer_or_nil(string)
    string && Integer(string) rescue nil
  end

  def name_for_date_and_chip_number(date, chip_number)
    date = Date.parse(date) unless date.class == Date
    return date.year.to_s + ("%02d" % date.month) +
          ("%02d" % date.day) + "_" + ("%02d" % chip_number)
  end

  def parse_date(options)
    return options[:date] if options[:date]
    return nil unless options['date(1i)'] && options['date(2i)'] && options['date(3i)']

    "#{options['date(1i)']}-#{options['date(2i)']}-#{options['date(3i)']}"
  end

  def duplicate_samples_specified
    case multi_arrays
    when false
      ids = sample_ids.values.collect do |chip|
        chip.values
      end
      ids.flatten!
    when true
      ids = sample_ids.values.collect do |chip|
        chip.values.each do |array|
          array.values
        end
      end
      ids.flatten!
    end

    if(ids.size > ids.uniq.size)
      self.array_entry_errors = "You've specified the same sample for multiple arrays"
      return true
    else
      return false
    end
  end
end
