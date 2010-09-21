class HybridizationSet
  # ActiveRecord-style validations
  include Validatable

  attr_accessor :previous_step
  attr_accessor :date
  attr_accessor :platform_id
  attr_accessor :number_of_chips
  attr_accessor :number_of_channels
  attr_accessor :chip_type_id
  attr_accessor :sample_ids
  attr_accessor :chip_names
  attr_accessor :hybridizations
  attr_accessor :chips
  attr_accessor :array_entry_errors

  # step 1 validations
  validates_presence_of :date, :groups => :step1
  validates_numericality_of :platform_id, :message => "must be selected",
    :groups => [:step1, :step2_no_multi_arrays, :step2_with_multi_arrays,
    :step3_no_multi_arrays, :step3_with_multi_arrays]

  # step 2 validations
  validates_numericality_of :number_of_chips,
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
  # * <tt>number_of_chips</tt> - Number of samples that will be hybridized
  # * <tt>number_of_channels</tt> - Number of channels per array
  # * <tt>chip_type_id</tt> - The chip type being used, only necessary for multi-arrays
  # * <tt>sample_ids</tt> - sample ids being used
  # * <tt>chip_names</tt> - user specified names for the chips, only used if chip numbering is off
  def initialize(options = {})
    options ||= {}
    @previous_step = options[:previous_step]
    @date = parse_date(options) || Date.today
    @platform_id = integer_or_nil(options[:platform_id])
    @number_of_chips = integer_or_nil(options[:number_of_chips])
    @number_of_channels = integer_or_nil(options[:number_of_channels])
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

  def number_of_arrays
    chip_type.arrays_per_chip
  end

  def save
    return false unless
      (valid_for_step1? && valid_for_step2_with_multi_arrays? && array_entries_complete?) ||
      (valid_for_step1? && valid_for_step2_no_multi_arrays? && array_entries_complete?)

    self.hybridizations = Array.new
    self.chips = Array.new

    return false if duplicate_samples_specified

    current_chip_number = 1
    begin
      Hybridization.transaction do
        chip_indexes = sample_ids.keys.collect {|i| i.to_i}
        chip_indexes.sort.each do |chip_index|
          chip_samples = sample_ids[chip_index.to_s]

          # use the chip names the user provided, or if there are none use the chip number
          if(chip_names)
            chip_name = chip_names[chip_index.to_s]
          else
            chip_name = name_for_date_and_chip_number(date, current_chip_number)
          end

          # with multi arrays
          if multi_arrays
            chip = Chip.create!(:name => chip_name)

            array_indexes = chip_samples.keys.collect {|i| i.to_i}
            array_indexes.sort.each do |array_index|
              array_samples = chip_samples[array_index.to_s]

              microarray = Microarray.create!(:chip_id => chip.id, :array_number => array_index.to_i+1)
              hybridization = Hybridization.create!(
                :hybridization_date => date,
                :chip_number => current_chip_number,
                :microarray_id => microarray.id,
                :samples => array_samples.values.collect{|s| Sample.find(s)}
              )

              self.hybridizations << hybridization
            end
            
            self.chips << chip.reload
          # no multi arrays
          else
            chip = Chip.create!(:name => chip_name)

            microarray = Microarray.create!(:chip_id => chip.id, :array_number => 1)
            hybridization = Hybridization.create!(
              :hybridization_date => date,
              :chip_number => current_chip_number,
              :microarray_id => microarray.id,
              :samples => chip_samples.values.collect{|s| Sample.find(s)}
            )

            self.hybridizations << hybridization
            self.chips << chip.reload
          end

          current_chip_number += 1
        end
      end

      Hybridization.record_charges(hybridizations) if SiteConfig.track_charges?
      Hybridization.record_as_chip_transactions(hybridizations) if SiteConfig.track_inventory?
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

    return true
  end

  # samples that are available to hybridize for the current platform
  def available_samples
    if(chip_type_id)
      @available_samples ||= Sample.find(
        :all,
        :conditions => "status = 'submitted' AND chip_type_id = #{chip_type_id}"
      )
    else
      @available_samples ||= Sample.find(
        :all,
        :include => :chip_type,
        :conditions => "status = 'submitted' AND chip_types.platform_id = #{platform.id}"
      )
    end
  end

  # chip types for the current platform
  def chip_types
    @chip_types ||= ChipType.find(
      :all,
      :conditions => {:platform_id => platform.id},
      :order => "name ASC"
    )
  end

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

    return Date.parse("#{options['date(1i)']}-#{options['date(2i)']}-#{options['date(3i)']}")
  end

  def array_entries_complete?
    return false unless sample_ids

    case multi_arrays
    when true
      sample_ids.each do |chip_index, chip_samples|
        chip_samples.each do |array_index, array_samples|
          array_samples.each do |channel_index, sample_id|
            return false if sample_id == 0
          end
        end
      end
    when false
      sample_ids.each do |chip_index, chip_samples|
        chip_samples.each do |channel_index, sample_id|
          return false if sample_id == 0
        end
      end
    end
  end

  def duplicate_samples_specified
    case multi_arrays
    when false
      ids = sample_ids.values.collect {|chip| chip.values}.flatten
      ids.flatten!
    when true
      chip_ids = sample_ids.values.collect {|chip| chip.values}.flatten
      ids = chip_ids.collect {|array| array.values}.flatten
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
