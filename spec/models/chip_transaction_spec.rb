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

  it "should handle chip borrow" do
    lab_group_1 = mock_model(LabGroup, :name => "Smith Lab")
    lab_group_2 = mock_model(LabGroup, :name => "Johnson Lab")
    chip_type = create_chip_type

    lambda {
      ChipTransaction.borrow(
        :date => Date.today,
        :to => lab_group_1,
        :from => lab_group_2,
        :chip_type => chip_type,
        :number => 5
      ).should be_true
    }.should change(ChipTransaction, :count).by(2)

    ChipTransaction.find(:first, :conditions => {
      :date => Date.today,
      :lab_group_id => lab_group_1.id,
      :chip_type_id => chip_type.id,
      :borrowed_in => 5,
      :description => "Borrowed from Johnson Lab"
    }).should_not be_nil

    ChipTransaction.find(:first, :conditions => {
      :date => Date.today,
      :lab_group_id => lab_group_2.id,
      :chip_type_id => chip_type.id,
      :borrowed_out => 5,
      :description => "Borrowed by Smith Lab"
    }).should_not be_nil
  end 

  it "should handle chip return borrowed" do
    lab_group_1 = mock_model(LabGroup, :name => "Smith Lab")
    lab_group_2 = mock_model(LabGroup, :name => "Johnson Lab")
    chip_type = create_chip_type

    lambda {
      ChipTransaction.return_borrowed(
        :date => Date.today,
        :to => lab_group_2,
        :from => lab_group_1,
        :chip_type => chip_type,
        :number => 5
      ).should be_true
    }.should change(ChipTransaction, :count).by(2)

    ChipTransaction.find(:first, :conditions => {
      :date => Date.today,
      :lab_group_id => lab_group_1.id,
      :chip_type_id => chip_type.id,
      :returned_out => 5,
      :description => "Returned to Johnson Lab"
    }).should_not be_nil

    ChipTransaction.find(:first, :conditions => {
      :date => Date.today,
      :lab_group_id => lab_group_2.id,
      :chip_type_id => chip_type.id,
      :returned_in => 5,
      :description => "Returned by Smith Lab"
    }).should_not be_nil
  end 

  describe "finding all transactions accessible to a user" do
    before(:each) do
      @user = mock( "User" )
      @transactions = mock("Transactions")
    end

    it "provides all transaction to a staff or admin user" do
      @user.should_receive(:staff_or_admin?).any_number_of_times.and_return(true)
      ChipTransaction.should_receive(:find).with(:all, :include => [:chip_type]).and_return(@transactions)
      ChipTransaction.accessible_to_user(@user).should == @transactions
    end

    it "provides only transactions that are part of a customer's lab groups" do
      @lab_groups = [mock_model(LabGroup)]
      @user.should_receive(:staff_or_admin?).and_return(false)
      @user.should_receive(:lab_groups).and_return(@lab_groups)
      ChipTransaction.should_receive(:find).with(:all, :conditions => ["lab_group_id IN (?)", [@lab_groups.first.id]],
        :include => [:chip_type]).and_return(@transactions)
      ChipTransaction.accessible_to_user(@user).should == @transactions
    end
  end
  
  it "groups transactions by lab group and chip type" do
    lab_group_1 = mock_model(LabGroup, :name => "Smith Lab")
    lab_group_2 = mock_model(LabGroup, :name => "Johnson Lab")
    chip_type_1 = create_chip_type(:name => "Mouse Chip")
    chip_type_2 = create_chip_type(:name => "Yeast Chip")

    LabGroup.should_receive(:all_by_id).and_return({
      lab_group_1.id => lab_group_1,
      lab_group_2.id => lab_group_2
    })

    transaction_1 = create_chip_transaction(:lab_group => lab_group_1, :chip_type => chip_type_1, :acquired => 20)
    transaction_2 = create_chip_transaction(:lab_group => lab_group_1, :chip_type => chip_type_1, :used => 10)
    transaction_3 = create_chip_transaction(:lab_group => lab_group_1, :chip_type => chip_type_2, :acquired => 30)
    transaction_4 = create_chip_transaction(:lab_group => lab_group_2, :chip_type => chip_type_2, :acquired => 5)

    transactions = [transaction_1, transaction_2, transaction_3, transaction_4]
    ChipTransaction.counts_by_lab_group_and_chip_type(transactions).should == {
      lab_group_1.name => {
        "lab_group_id" => lab_group_1.id,
        chip_type_1.platform_and_name => {
          "owed_out"=>0, "returned_in"=>0, "borrowed_in"=>0, "used"=>10, "acquired"=>20, "owed_in"=>0,
          "borrowed_out"=>0, "chips"=>10, "returned_out"=>0, "traded_sold"=>0,
          "chip_type_id" => chip_type_1.id
        },
        chip_type_2.platform_and_name => {
          "owed_out"=>0, "returned_in"=>0, "borrowed_in"=>0, "used"=>0, "acquired"=>30, "owed_in"=>0,
          "borrowed_out"=>0, "chips"=>30, "returned_out"=>0, "traded_sold"=>0,
          "chip_type_id" => chip_type_2.id
        }
      },
      lab_group_2.name => {
        "lab_group_id" => lab_group_2.id,
        chip_type_2.platform_and_name => {
          "owed_out"=>0, "returned_in"=>0, "borrowed_in"=>0, "used"=>0, "acquired"=>5, "owed_in"=>0,
          "borrowed_out"=>0, "chips"=>5, "returned_out"=>0, "traded_sold"=>0,
          "chip_type_id" => chip_type_2.id
        }
      }
    }
  end
end
