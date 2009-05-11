class ChipPurchase
  include Validatable
  
  attr_accessor :date
  attr_accessor :lab_group_id
  attr_accessor :chip_type_id
  attr_accessor :number
  attr_accessor :description

  validates_presence_of :date, :lab_group_id, :chip_type_id, :description
  validates_numericality_of :number, :message => "of chips must be a number"

  def initialize(options = {})
    @date = options[:date] || Date.today
    @lab_group_id = options[:lab_group_id]
    @chip_type_id = options[:chip_type_id]
    @description = options[:description] || nil
    @number = options[:number] || 0
  end

  def save
    transaction = ChipTransaction.new(
      :date => @date,
      :lab_group_id => @lab_group_id,
      :chip_type_id => @chip_type_id,
      :description => @description,
      :acquired => @number
    )

    transaction.save
  end
end
