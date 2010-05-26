require 'spec_helper'

describe QcMetric do
  describe "validating a new QC metric" do
    it "should be valid with a unique name" do
      QcMetric.new(:name => "Saturated Spots").should be_valid
    end

    it "should not be valid without a name" do
      QcMetric.new.should_not be_valid
    end

    it "should not be valid with a name that's already been used" do
      QcMetric.create(:name => "Saturated Spots")
      QcMetric.new(:name => "Saturated Spots").should_not be_valid
    end
  end
end
