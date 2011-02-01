class ChipTransaction < ActiveRecord::Base
  belongs_to :lab_group
  belongs_to :chip_type
  
  validates_associated :chip_type
  validates_presence_of :description
  validates_format_of :acquired_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :used_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :traded_sold_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :borrowed_in_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :returned_out_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :borrowed_out_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :returned_in_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_length_of :description, :maximum=>250 

  def self.has_transactions?(group_id, type_id)
    if(find_all_in_lab_group_chip_type(group_id, type_id).size > 0)
      return true
    else
      return false
    end
  end

  def self.find_all_in_lab_group_chip_type(group_id, type_id)
    find(
          :all, 
          :conditions => ["lab_group_id = :lab_group_id AND chip_type_id = :chip_type_id",
                          { :lab_group_id => group_id, :chip_type_id => type_id } ],
          :order => "date DESC")
  end

  def self.get_chip_totals(chip_transactions)
    @totals = Hash.new(0)
    for transaction in chip_transactions
      if transaction.acquired != nil
        @totals['acquired'] += transaction.acquired
        @totals['chips'] += transaction.acquired
      end
      if transaction.used != nil
        @totals['used'] += transaction.used
        @totals['chips'] -= transaction.used
      end
      if transaction.traded_sold != nil
        @totals['traded_sold'] += transaction.traded_sold
        @totals['chips'] -= transaction.traded_sold
      end
      if transaction.borrowed_in != nil
        @totals['borrowed_in'] += transaction.borrowed_in
        @totals['chips'] += transaction.borrowed_in
      end
      if transaction.returned_out != nil
        @totals['returned_out'] += transaction.returned_out
        @totals['chips'] -= transaction.returned_out
      end
      if transaction.borrowed_out != nil
        @totals['borrowed_out'] += transaction.borrowed_out
        @totals['chips'] -= transaction.borrowed_out
      end
      if transaction.returned_in != nil
        @totals['returned_in'] += transaction.returned_in
        @totals['chips'] += transaction.returned_in
      end
    end
    
    # net number owed to other lab groups
    @totals['owed_out'] = @totals['borrowed_in'] - @totals['returned_out']
    
    # net number owed by other lab groups
    @totals['owed_in'] = @totals['borrowed_out'] - @totals['returned_in']
    
    return @totals
  end

  # borrow accepts an option hash with the following parameters:
  #
  # * <tt>date</tt> - The date of the transaction
  # * <tt>to</tt> - The LabGroup borrowing arrays
  # * <tt>from</tt> - The LabGroup loaning arrays
  # * <tt>chip_type</tt> - The ChipType being bought
  # * <tt>number</tt> - The number of arrays bought
  def self.borrow(options = {})
    in_transaction = ChipTransaction.new(
      :date => options[:date],
      :lab_group => options[:to],
      :chip_type => options[:chip_type],
      :description => "Borrowed from #{options[:from].name}",
      :borrowed_in => options[:number]
    )

    out_transaction = ChipTransaction.new(
      :date => options[:date],
      :lab_group => options[:from],
      :chip_type => options[:chip_type],
      :description => "Borrowed by #{options[:to].name}",
      :borrowed_out => options[:number]
    )

    in_transaction.save && out_transaction.save
  end

  # return_borrowed accepts an option hash with the following parameters:
  #
  # * <tt>date</tt> - The date of the transaction
  # * <tt>to</tt> - The LabGroup borrowing arrays
  # * <tt>from</tt> - The LabGroup loaning arrays
  # * <tt>chip_type</tt> - The ChipType being bought
  # * <tt>number</tt> - The number of arrays bought
  def self.return_borrowed(options = {})
    out_transaction = ChipTransaction.new(
      :date => options[:date],
      :lab_group => options[:from],
      :chip_type => options[:chip_type],
      :description => "Returned to #{options[:to].name}",
      :returned_out => options[:number]
    )

    in_transaction = ChipTransaction.new(
      :date => options[:date],
      :lab_group => options[:to],
      :chip_type => options[:chip_type],
      :description => "Returned by #{options[:from].name}",
      :returned_in => options[:number]
    )

    out_transaction.save && in_transaction.save
  end

  def self.accessible_to_user(user)
    if user.staff_or_admin?
      return ChipTransaction.find(:all, :include => [:chip_type])
    else
      lab_groups = user.lab_groups

      if lab_groups.empty?
        return Array.new
      else
        return ChipTransaction.find(:all, :conditions => ["lab_group_id IN (?)", lab_groups.collect{|g| g.id}],
          :include => [:chip_type])
      end
    end
  end

  def self.counts_by_lab_group_and_chip_type(transactions)
    lab_groups_by_id = LabGroup.all_by_id

    by_lab_group = transactions.group_by{|t| lab_groups_by_id[t.lab_group_id].name}

    ret = Hash.new
    by_lab_group.each do |lab_group, lab_group_transactions|
      by_chip_type = lab_group_transactions.group_by{|t| t.chip_type.platform_and_name}

      ret[lab_group] = {"lab_group_id" => lab_group_transactions.first.lab_group_id}
      by_chip_type.each do |chip_type, chip_type_transactions|
        ret[lab_group][chip_type] = get_chip_totals(chip_type_transactions).merge(
          "chip_type_id" => chip_type_transactions.first.chip_type_id
        )
      end
    end

    return ret
  end
end
