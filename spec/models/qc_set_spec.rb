require 'spec_helper'

describe QcSet do
  describe "validating a new QC set" do
    it "should be valid with a valid hybridization" do
      hybridization = create_hybridization
      QcSet.new(:hybridization => hybridization).should be_valid
    end

    it "should not be valid without a hybridization_id" do
      QcSet.new.should_not be_valid
    end

    # a new QcSet is valid with a fake hybridization_id even though validates_associated is used: why?
    #
    #it "should not be valid with a hybridization_id for a hybridization that doesn't exist" do
    #  debugger
    #  QcSet.new(:hybridization_id => 3245).should_not be_valid
    #end
  end
end
