require 'spec_helper'

describe ServiceOption do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :chip_cost => 1.5,
      :labeling_cost => 1.5,
      :hybridization_cost => 1.5,
      :qc_cost => 1.5,
      :other_cost => 1.5
    }
  end

  it "should create a new instance given valid attributes" do
    ServiceOption.create!(@valid_attributes)
  end
end
