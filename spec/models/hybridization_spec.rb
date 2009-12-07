require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hybridization do
  describe "recording chip transactions" do
    def do_record
      @chip_transactions = Hybridization.record_as_chip_transactions(@hybridizations)
    end

    it "should create a single transaction for hybridizations with the same date/lab/chip " do
      project = create_project
      chip_type = create_chip_type
      @hybridizations = [
        create_hybridization(
          :samples => [create_sample(:project => project, :chip_type => chip_type)],
          :chip_number => 1
        ),
        create_hybridization(
          :samples => [create_sample(:project => project, :chip_type => chip_type)],
          :chip_number => 2
        ),
        create_hybridization(
          :samples => [create_sample(:project => project, :chip_type => chip_type)],
          :chip_number => 3
        )
      ]

      do_record

      @chip_transactions.size.should == 1
      @chip_transactions[0].lab_group.should == project.lab_group
      @chip_transactions[0].chip_type.should == chip_type
      @chip_transactions[0].used.should == 3
    end

    it "should create two transaction when hybridizations span different labs/chips" do
      @hybridizations = [
        create_hybridization(
          :samples => [create_sample],
          :chip_number => 1
        ),
        create_hybridization(
          :samples => [create_sample],
          :chip_number => 2
        )
      ]

      do_record

      @chip_transactions.size.should == 2
    end
  end

  it "should create GCOS import files" do
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:gcos_output_path => "#{RAILS_ROOT}")
    @site_config.save
    
    hybridization = create_hybridization(
      :hybridization_date => "2009-02-25",
      :samples => [create_sample(:sample_name => "test")],
      :chip_number => 1
    )
    hybridization.create_gcos_import_file

    # make sure gcos file was created, then delete it
    File.exists?("#{RAILS_ROOT}/20090225_01_test.txt").should be_true
    FileUtils.rm("#{RAILS_ROOT}/20090225_01_test.txt")
  end

  it "should create an Affymetrix GeneChip Commnad Console (AGCC) array (ARR) file" do
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:agcc_output_path => "#{RAILS_ROOT}")
    @site_config.save

    hybridization = create_hybridization(
      :hybridization_date => "2009-02-25",
      :samples => [create_sample(:sample_name => "test")],
      :chip_number => 1
    )
    hybridization.create_agcc_array_file

    # make sure gcos file was created, then delete it
    File.exists?("#{RAILS_ROOT}/20090225_01_test.ARR").should be_true
    FileUtils.rm("#{RAILS_ROOT}/20090225_01_test.ARR")
  end

  describe "providing the highest chip number for a particular date" do

    it "should provide 0 if there are no hybridizations on that date" do
      Hybridization.highest_chip_number('2009-06-30').should == 0
    end

    it "should provide the highest chip_number for that date if hybridiations exist" do
      create_hybridization(:hybridization_date => '2009-06-29', :chip_number => 1)
      create_hybridization(:hybridization_date => '2009-06-29', :chip_number => 2)

      Hybridization.highest_chip_number('2009-06-29').should == 2
    end

  end

end
