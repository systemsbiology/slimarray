class ChipPurchase
  include Validatable
  include DateParser
  
  attr_accessor :date
  attr_accessor :lab_group_id
  attr_accessor :chip_type_id
  attr_accessor :number
  attr_accessor :description

  validates_presence_of :date, :lab_group_id, :chip_type_id, :description
  validates_numericality_of :number, :message => "of chips must be a number"

  # initialize accepts an option hash with the following parameters:
  #
  # * <tt>date</tt> - The date of the transaction
  # * <tt>buyer</tt> - The LabGroup buying arrays
  # * <tt>seller</tt> - The LabGroup selling arrays
  # * <tt>chip_type</tt> - The ChipType being bought
  # * <tt>number</tt> - The number of arrays bought
  def initialize(options = {})
    @date = parse_date(options["date(1i)"], options["date(2i)"], options["date(3i)"])
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
