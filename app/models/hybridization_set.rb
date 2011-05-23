class HybridizationSet
  attr_accessor :chips

  def initialize(attributes)
    @chips = Array.new

    attributes["chips"].sort{|a,b| a[0].to_i <=> b[0].to_i}.each do |index, chip_attributes|
      chip = Chip.find(chip_attributes["id"])
      chip.name = chip_attributes["name"]

      @chips << chip
    end
  end

  def save
    @chips.each do |chip|
      chip.hybridize!
    end

    Chip.record_chip_transactions(@chips)

    return self
  end

end
