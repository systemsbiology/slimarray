require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChipType" do
  fixtures :chip_types, :samples, :hybridizations, :inventory_checks, :chip_transactions

  it "destroy warning" do
    expected_warning = "Destroying this chip type will also destroy:\n" + 
                       "6 sample(s)\n" +
                       "2 inventory check(s)\n" +
                       "2 chip transaction(s)\n" +
                       "Are you sure you want to destroy it?"
  
    type = ChipType.find( chip_types(:alligator) )   
    type.destroy_warning.should == expected_warning
  end
end
