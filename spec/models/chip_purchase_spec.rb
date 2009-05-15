require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChipPurchase" do

  it "should create a chip purchase" do
    lab_group = mock_model(LabGroup)
    chip_type = create_chip_type

    lambda {
      purchase = ChipPurchase.new(
        :date => Date.today,
        :lab_group_id => lab_group.id,
        :chip_type_id => chip_type.id,
        :number => 5,
        :description => "Box of 5 arrays"
      ).should be_true
      purchase.save
    }.should change(ChipTransaction, :count).by(1)

    ChipTransaction.find(:first, :conditions => {
      :date => Date.today,
      :lab_group_id => lab_group.id,
      :chip_type_id => chip_type.id,
      :acquired => 5,
      :description => "Box of 5 arrays"
    }).should_not be_nil
  end 

end
