class HybridizationSet
  include SharedMethods

  attr_accessor :chips

  def initialize(attributes)
    @chips = Array.new

    sort_attributes_numerically(attributes["chips"]).each do |index, chip_attributes|
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
