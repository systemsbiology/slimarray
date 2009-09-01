require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "InventoryCheck" do
  fixtures :inventory_checks

  it "should provide the name of the associated lab group" do
    inventory_check = create_inventory_check
    lab_group = mock_model(LabGroup, :name => "Yeast Lab")
    inventory_check.stub!(:lab_group_id).and_return(lab_group.id)
    LabGroup.stub!(:all_by_id).and_return({lab_group.id => lab_group})

    inventory_check.lab_group_name.should == "Yeast Lab"
  end
end
