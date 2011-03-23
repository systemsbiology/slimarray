class HybridizationSet
  attr_accessor :chips

  def initialize(attributes)
    @chips = Array.new

    attributes["chips"].each do |index, chip_attributes|
      chip = Chip.find(chip_attributes["id"])
      chip.name = chip_attributes["name"]

      @chips << chip
    end
  end

  def save
    @chips.each do |chip|
      chip.status = "hybridized"
      chip.hybridization_date = Date.today
      chip.save

      chip.microarrays.each{|microarray| microarray.create_gcos_import_file} if SiteConfig.create_gcos_files?
      chip.microarrays.each{|microarray| microarray.create_agcc_array_file} if SiteConfig.create_agcc_files?
      chip.microarrays.each{|microarray| microarray.record_charge}
    end

    record_chip_transactions

    return self
  end

  def record_chip_transactions
    hybs_per_date_group_chip = Hash.new

    for chip in @chips
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

end
