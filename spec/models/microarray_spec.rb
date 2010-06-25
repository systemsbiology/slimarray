require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Microarray do
  it "should have a name" do
    label_b = create_label(:name => "b")
    label_a = create_label(:name => "a")
    sample_1 = create_sample(:sample_name => "Time_0", :label => label_a)
    sample_2 = create_sample(:sample_name => "Time_60", :label => label_b)
    microarray = create_microarray
    hybridization = create_hybridization(:samples => [sample_2, sample_1], :microarray => microarray)

    microarray.name.should == "Time_0_v_Time_60"
  end
end
