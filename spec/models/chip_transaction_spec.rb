require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChipTransaction" do
  fixtures :chip_types, :lab_groups, :chip_transactions

  it "should find all transactions for a lab group and chip type" do
    # mock this call since it uses lab groups, which may be ActiveResources
    ChipTransaction.should_receive(:find).with(
      :all,
      :conditions => ["lab_group_id = :lab_group_id AND chip_type_id = :chip_type_id",
                          { :lab_group_id => 6, :chip_type_id => 2 } ],
      :order => "date DESC"
    ).and_return( [mock_model(ChipTransaction), mock_model(ChipTransaction)] )
    transactions = ChipTransaction.find_all_in_lab_group_chip_type(
      6,
      2
    )
    
    transactions.size.should == 2
  end

  it "should indicate if it has transactions for a lab group and chip type" do
    ChipTransaction.should_receive(:find_all_in_lab_group_chip_type).with(6,2).and_return(
      [mock_model(ChipTransaction), mock_model(ChipTransaction)]
    )
    ChipTransaction.has_transactions?(6,2).should be_true
  end

  it "should indicate if it does not have transactions for a lab group and chip type" do
    ChipTransaction.should_receive(:find_all_in_lab_group_chip_type).with(6,2).and_return(
      []
    )
    ChipTransaction.has_transactions?(6,2).should be_false
  end

  it "should provide totals for a set of chip transactions" do
    transactions = [
      create_chip_transaction(:acquired => 30),
      create_chip_transaction(:used => 25),
      create_chip_transaction(:traded_sold => 5),
      create_chip_transaction(:borrowed_in => 10),
      create_chip_transaction(:returned_out => 5),
      create_chip_transaction(:borrowed_out => 5),
      create_chip_transaction(:returned_in => 2),
    ]

    expected_totals = {
      'acquired' => 30,
      'used' => 25,
      'traded_sold' => 5,
      'borrowed_in' => 10,
      'returned_out' => 5,
      'borrowed_out' => 5,
      'returned_in' => 2,
      'chips' => 2,
      'owed_out' => 5,
      'owed_in' => 3
    }

    ChipTransaction.get_chip_totals(transactions).should == expected_totals
  end
end
