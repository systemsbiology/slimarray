require 'spec_helper'

describe QCThreshold do
  before(:each) do
    @valid_attributes = {
      :platform_id => 1,
      :qc_metric_id => 1,
      :lower_limit => 1.5,
      :upper_limit => 1.5,
      :should_contain => "value for should_contain",
      :should_not_contain => "value for should_not_contain"
    }
  end

  it "should create a new instance given valid attributes" do
    QCThreshold.create!(@valid_attributes)
  end
end
