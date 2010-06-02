require 'spec_helper'

describe QcSet do
  describe "validating a new QC set where the hybridization is directly specified" do
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

  describe "making a new QC set with chip/array identifiers, statistics and a file" do
    it "should be valid if the chip/array point to a hybridization" do
      hybridization = create_hybridization
      microarray = hybridization.microarray
      chip = microarray.chip

      qc_set = QcSet.new("chip_name" => chip.name, "array_number" => microarray.array_number,
        "statistics" => {"Good probes" => 1000, "Bad probes" => 10},
        "file" => "/path/to/qc_file")

      qc_set.should be_valid
    end

    it "should not be valid if the chip name doesn't point to an actual chip" do
      hybridization = create_hybridization
      microarray = hybridization.microarray
      chip = microarray.chip

      qc_set = QcSet.new("chip_name" => "1234", "array_number" => microarray.array_number,
        "statistics" => {"Good probes" => 1000, "Bad probes" => 10},
        "file" => "/path/to/qc_file")

      qc_set.should_not be_valid
    end

    it "should not be valid if the array number isn't an array on the chip" do
      hybridization = create_hybridization
      microarray = hybridization.microarray
      chip = microarray.chip

      qc_set = QcSet.new("chip_name" => chip.name, "array_number" => 42,
        "statistics" => {"Good probes" => 1000, "Bad probes" => 10},
        "file" => "/path/to/qc_file")

      qc_set.should_not be_valid
    end

    it "should make an associated QC file if a file path is provided" do
      hybridization = create_hybridization
      microarray = hybridization.microarray
      chip = microarray.chip

      qc_set = QcSet.new("chip_name" => chip.name, "array_number" => microarray.array_number,
        "statistics" => {"Good probes" => 1000, "Bad probes" => 10},
        "file" => "/path/to/qc_file")

      qc_set.qc_files.size.should == 1
      qc_set.qc_files.first.path.should == "/path/to/qc_file"
    end

    it "should make associated QC statistics if they are provided" do
      hybridization = create_hybridization
      microarray = hybridization.microarray
      chip = microarray.chip

      qc_set = QcSet.new("chip_name" => chip.name, "array_number" => microarray.array_number,
        "statistics" => {"Good probes" => 1000, "Bad probes" => 10},
        "file" => "/path/to/qc_file")

      good_metric = QcMetric.find_by_name("Good probes")
      good_metric.should_not be_nil
      bad_metric = QcMetric.find_by_name("Bad probes")
      bad_metric.should_not be_nil
      expected_good_attributes = QcStatistic.new(:qc_metric => good_metric, :value => 1000).attributes
      expected_bad_attributes = QcStatistic.new(:qc_metric => bad_metric, :value => 10).attributes

      statistic_attributes = qc_set.qc_statistics.collect{|x| x.attributes}
      statistic_attributes.should include(expected_good_attributes)
      statistic_attributes.should include(expected_bad_attributes)
    end
  end
end