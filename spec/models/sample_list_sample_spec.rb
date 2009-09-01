require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleListSample do
  before(:each) do
    @valid_attributes = {
      :sample_id => 1,
      :sample_list_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    SampleListSample.create!(@valid_attributes)
  end
end
