require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChipBorrow" do

  it "should create a chip inter-group purchase" do
    lab_group_1 = mock_model(LabGroup, :name => "Smith Lab")
    lab_group_2 = mock_model(LabGroup, :name => "Johnson Lab")
    LabGroup.should_receive(:find).with(lab_group_1.id).and_return(lab_group_1)
    LabGroup.should_receive(:find).with(lab_group_2.id).and_return(lab_group_2)
    chip_type = create_chip_type

    lambda {
      borrow = ChipBorrow.new(
        :date => Date.today,
        :to_lab_group_id => lab_group_1.id,
        :from_lab_group_id => lab_group_2.id,
        :chip_type_id => chip_type.id,
        :number => 5
      ).should be_true
      borrow.save
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

end
