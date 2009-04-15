require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChargeSet" do
  fixtures :charge_sets, :charges

  it "should provide various totals" do
    expected_totals = Hash.new(0)
    expected_totals['chips'] = 1
    expected_totals['chip_cost'] = 400
    expected_totals['labeling_cost'] = 280
    expected_totals['hybridization_cost'] = 100
    expected_totals['qc_cost'] = 25
    expected_totals['other_cost'] = 0
    expected_totals['total_cost'] = 805

    set = charge_sets(:mouse_jan)
    set.get_totals.should == expected_totals
  end

  it "should provide a destroy warning" do
    expected_warning = "Destroying this charge set will also destroy:\n" + 
                       "2 charge(s)\n" +
                       "Are you sure you want to destroy it?"
  
    set = charge_sets(:mouse_jan)
    set.destroy_warning.should == expected_warning
  end
end
