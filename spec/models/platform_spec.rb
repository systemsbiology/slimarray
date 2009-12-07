require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Platform do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :has_multi_array_chips => false,
      :uses_chip_numbers => false
    }
  end

  it "should create a new instance given valid attributes" do
    Platform.create!(@valid_attributes)
  end
end
