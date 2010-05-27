require 'spec_helper'

describe QcFile do
  describe "validating a new QC file" do
    it "should be valid with a QC set and a path" do
      QcFile.new(:qc_set => create_qc_set, :path => "/path/to/file").should be_valid
    end

    it "should be valid without a QC set" do
      QcFile.new(:path => "/path/to/file").should be_valid
    end

    it "should not be valid without a path" do
      QcFile.new(:qc_set => create_qc_set).should_not be_valid
    end
  end
end
