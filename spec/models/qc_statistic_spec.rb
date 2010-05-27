require 'spec_helper'

describe QcStatistic do
  describe "validating a new QC statistic" do
    it "should be valid with a QC set and a QC metric" do
      qc_set = create_qc_set
      qc_metric = create_qc_metric

      QcStatistic.new(:qc_set => qc_set, :qc_metric => qc_metric).should be_valid
    end

    it "should be valid without a QC set" do
      qc_metric = create_qc_metric

      QcStatistic.new(:qc_metric => qc_metric).should be_valid
    end

    it "should not be valid without a QC metric" do
      qc_set = create_qc_set

      QcStatistic.new(:qc_set => qc_set).should_not be_valid
    end
  end
end
