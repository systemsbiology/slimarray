class ChipReturn
  include Validatable
  include DateParser
  
  attr_accessor :date
  attr_accessor :to_lab_group_id
  attr_accessor :from_lab_group_id
  attr_accessor :chip_type_id
  attr_accessor :number

  validates_presence_of :date, :to_lab_group_id, :from_lab_group_id, :chip_type_id
  validates_numericality_of :number, :message => "of chips must be a number"

  # initialize accepts an option hash with the following parameters:
  #
  # * <tt>date</tt> - The date of the transaction
  # * <tt>buyer</tt> - The LabGroup returning arrays
  # * <tt>seller</tt> - The LabGroup lending arrays
  # * <tt>chip_type</tt> - The ChipType being bought
  # * <tt>number</tt> - The number of arrays bought
  def initialize(options = {})
    @date = parse_date(options["date(1i)"], options["date(2i)"], options["date(3i)"])
    @to_lab_group_id = options[:to_lab_group_id]
    @from_lab_group_id = options[:from_lab_group_id]
    @chip_type_id = options[:chip_type_id]
    @number = options[:number] || 0
  end

  def save
    to = LabGroup.find(@to_lab_group_id)
    from = LabGroup.find(@from_lab_group_id)

    buy_transaction = ChipTransaction.new(
      :date => @date,
      :lab_group_id => @to_lab_group_id,
      :chip_type_id => @chip_type_id,
      :description => "Returned to #{from.name}",
      :returned_in => @number
    )

    sell_transaction = ChipTransaction.new(
      :date => @date,
      :lab_group_id => @from_lab_group_id,
      :chip_type_id => @chip_type_id,
      :description => "Returned by #{to.name}",
      :returned_out => @number
    )

    buy_transaction.save && sell_transaction.save
  end
end
