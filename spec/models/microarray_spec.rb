require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Microarray do
  before(:each) do
    @valid_attributes = {
      :chip_id => 1,
      :array_number => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Microarray.create!(@valid_attributes)
  end
end
