require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChipReturn" do

  it "should create a chip return" do
    lab_group_1 = mock_model(LabGroup, :name => "Smith Lab")
    lab_group_2 = mock_model(LabGroup, :name => "Johnson Lab")
    LabGroup.should_receive(:find).with(lab_group_1.id).and_return(lab_group_1)
    LabGroup.should_receive(:find).with(lab_group_2.id).and_return(lab_group_2)
    chip_type = create_chip_type

    lambda {
      borrow = ChipReturn.new(
        :date => Date.today,
        :to_lab_group_id => lab_group_1.id,
        :from_lab_group_id => lab_group_2.id,
        :chip_type_id => chip_type.id,
        :number => 5
      )
      borrow.save.should be_true
    }.should change(ChipTransaction, :count).by(2)

    ChipTransaction.find(:first, :conditions => {
      :date => Date.today,
      :lab_group_id => lab_group_1.id,
      :chip_type_id => chip_type.id,
      :returned_in => 5,
      :description => "Returned to Johnson Lab"
    }).should_not be_nil

    ChipTransaction.find(:first, :conditions => {
      :date => Date.today,
      :lab_group_id => lab_group_2.id,
      :chip_type_id => chip_type.id,
      :returned_out => 5,
      :description => "Returned by Smith Lab"
    }).should_not be_nil
  end 

end
