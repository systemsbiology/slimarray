class Chip < ActiveRecord::Base
  belongs_to :sample_set

  has_many :microarrays, :dependent => :destroy
  #accepts_nested_attributes_for :microarrays

  validate :no_redundant_samples

  def microarrays_attributes=(attributes)
    attributes.sort.each do |key, microarray_attributes|
      microarray = microarrays.build(microarray_attributes.merge(:chip => self))
    end
  end

  def hybridize!
    update_attribute('status', 'hybridized')
    
    set_hybridization_date
    record_charges
    create_gcos_import_files
    create_agcc_array_files
  end

  def set_hybridization_date
    update_attribute('hybridization_date', Date.today)
  end

  def record_charges
    microarrays.each{|microarray| microarray.record_charge}
  end

  def create_gcos_import_files
    microarrays.each{|microarray| microarray.create_gcos_import_file} if SiteConfig.create_gcos_files?
  end

  def create_agcc_array_files
    microarrays.each{|microarray| microarray.create_agcc_array_file} if SiteConfig.create_agcc_files?
  end

  def self.record_chip_transactions(chips)
    hybs_per_date_group_chip = Hash.new

    for chip in chips
      date = chip.hybridization_date
      hybs_per_date_group_chip[date] ||= Hash.new

      lab_group_id = chip.sample_set.project.lab_group_id
      hybs_per_date_group_chip[date][lab_group_id] ||= Hash.new
      
      chip_type_id = chip.sample_set.chip_type_id
      hybs_per_date_group_chip[date][lab_group_id][chip_type_id] ||= 0
      hybs_per_date_group_chip[date][lab_group_id][chip_type_id] += 1
    end

    transactions = Array.new
    hybs_per_date_group_chip.each do |date, group_hash|
      group_hash.each do |lab_group_id, chip_hash|
        chip_hash.each do |chip_type_id, chip_count|
          chip_type = ChipType.find(chip_type_id)

          transactions << ChipTransaction.create(
            :lab_group_id => lab_group_id,
            :chip_type_id => chip_type_id,
            :date => date,
            :description => 'Hybridized on ' + date.to_s,
            :used => chip_count
          )
        end
      end
    end      

    return transactions
  end

  def no_redundant_samples
    samples = Array.new

    microarrays.each do |microarray|
      samples += microarray.samples
    end

    if samples.uniq.size != samples.size
      errors.add_to_base("The same sample can't appear on multiple arrays")
    end
  end

  def update_attributes(attributes)
    hybridized = attributes.delete("hybridized")
    
    if hybridized == "1"
      attributes["status"] = "hybridized"
    elsif hybridized == "0"
      attributes["status"] = "submitted"
      attributes.delete("hybridization_date")
    end

    super
  end

  def hybridized
    status == "hybridized"
  end

  def available_samples
    Sample.find(:all, :include => {:microarray => :chip},
      :conditions => ["chips.status = 'submitted' OR microarray_id IS NULL OR microarray_id IN (?)", microarray_ids])
  end

  def layout
    channels = sample_set.service_option.channels
    arrays_per_chip = sample_set.chip_type.arrays_per_chip

    layout = Array.new

    if arrays_per_chip == 1
      # 1 array/slide, 1 channel
      if channels == 1
        layout = [
          { :title => "Chip/Slide",
            :samples => [
              { :title => "Channel 1", :array => 1, :channel => 1,
                :sample_id => microarrays.first.samples.first.id,
                :microarray_id => microarrays.first.id }
            ]
          }
        ]
      # 1 array/slide, multiple (usually 2) channels
      else
        microarray = microarrays.first
        microarray_id = microarray && microarray.id

        layout = [{
          :title => "Chip/Slide",
          :samples => 
          (1..channels).collect do |channel|
            sample_id = microarray.samples[channel-1].id
            { :title => "Channel #{channel}", :array => 1, :channel => channel,
              :sample_id => sample_id, :microarray_id => microarray_id }
          end
        }]
      end
    else
      # multiple arrays/slide, 1 channel
      if channels == 1
        (1..arrays_per_chip).each do |array|
          microarray = microarrays[array-1]
          microarray_id = microarray && microarray.id
          sample = microarray && microarray.samples.first
          sample_id = sample && sample.id

          layout << {
            :title => "Array #{array}",
            :samples => [
              { :title => "Channel 1", :array => array, :channel => 1,
                :sample_id => sample_id, :microarray_id => microarray_id }
            ]
          }
        end
      # multiple arrays/slide, multiple (usually 2) channels
      else
        (1..arrays_per_chip).each do |array|
          microarray = microarrays[array-1]
          microarray_id = microarray && microarray.id

          layout << {
            :title => "Array #{array}",
            :samples => (1..channels).collect do |channel|
              sample = microarray && microarray.samples[channel-1]
              sample_id = sample && sample.id
              { :title => "Channel #{channel}", :array => array,
                :channel => channel, :sample_id => sample_id, :microarray_id => microarray_id }
            end
          }
        end
      end
    end

    return layout
  end

  def hybridization_date_number_string
    hybridization_date ||= Date.today

    return hybridization_date.year.to_s + ("%02d" % hybridization_date.month) +
                           ("%02d" % hybridization_date.day) + "_" + ("%02d" % chip_number)
  end

  def default_name
    if sample_set.chip_type.platform.uses_chip_numbers
      return hybridization_date_number_string + "_" + microarrays.first.name
    else
      return ""
    end
  end
end
