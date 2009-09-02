require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "BioanalyzerRun" do
  fixtures :site_config

  before(:each) do
    # point site settings at test set of bioanalyzer files
    site_config = SiteConfig.find(1)
    site_config.bioanalyzer_pickup = "#{RAILS_ROOT}/spec/fixtures/bioanalyzer_files"
    site_config.save
  end
      
  describe "importing new runs" do

    before(:each) do
      # trash the Bioanalyzer data that's already loaded
      BioanalyzerRun.find(:all).each do |r|
        r.destroy
      end

      @mock_lab_group = mock_model(LabGroup, :id => 3)
      LabGroup.should_receive(:find_by_name).with("JDRF").
        any_number_of_times.and_return(nil)
      LabGroup.should_receive(:find_by_name).with("AlligatorGroup").
        any_number_of_times.and_return(@mock_lab_group)
      LabGroup.should_receive(:find_by_name).with("gorillaz").
        any_number_of_times.and_return(@mock_lab_group)

      @mock_user = mock_model(User, :email => "user@example.com")
      User.should_receive(:find).any_number_of_times.and_return(@mock_user)
    end

    it "should import new runs" do
      num_bioanalyzer_runs = BioanalyzerRun.count
      num_quality_traces = QualityTrace.count
      
      BioanalyzerRun.import_new

      BioanalyzerRun.count.should == num_bioanalyzer_runs + 2
      # 12 samples + ladder from one chip, and 2 samples + ladder
      # for the 2nd chip
      QualityTrace.count.should == num_quality_traces + 18

      # verify that Control_1 total RNA sample, which was encountered twice,
      # is named appropriately (Control_1 and Control_1_r1)
      duplicate_traces = QualityTrace.find(:all, :conditions => ["name LIKE ? AND sample_type = 'total'", "Control_1%"])
      duplicate_traces.size.should == 2
      found_name_1 = false
      found_name_2 = false
      for trace in duplicate_traces
        if(trace.name == "Control_1")
          found_name_1 = true
        end
        if(trace.name == "Control_1_r1")
          found_name_2 = true
        end
      end
      found_name_1.should_not be_nil
      found_name_2.should_not be_nil
    end
    
    # ensure that import calls subsequent to the initial one that
    # find the data don't reimport duplicate runs/traces
    it "should not create new records when import is run on the same files twice" do
      num_bioanalyzer_runs = BioanalyzerRun.count
      num_quality_traces = QualityTrace.count
      
      BioanalyzerRun.import_new

      BioanalyzerRun.count.should == num_bioanalyzer_runs + 2
      QualityTrace.count.should == num_quality_traces + 18

      BioanalyzerRun.import_new

      BioanalyzerRun.count.should == num_bioanalyzer_runs + 2
      QualityTrace.count.should == num_quality_traces + 18
    end
  end

  describe "finding for a user" do
    fixtures :bioanalyzer_runs, :quality_traces
    
    before(:each) do
      @mock_user = mock_model(User)
    end

    it "should return an empty array if the user has access to no lab groups" do
      @mock_user.should_receive(:get_lab_group_ids).and_return( [] )
      BioanalyzerRun.find_for_user(@mock_user).should == []
    end

    it "should return an empty array if the user has no accessible quality traces" do
      @mock_user.should_receive(:get_lab_group_ids).and_return( [42] )
      BioanalyzerRun.find_for_user(@mock_user).should == []
    end

    it "should return an array of accessible bioanalyzer runs" do
      lab_group_id = quality_traces(:quality_trace_00001).lab_group_id
      @mock_user.should_receive(:get_lab_group_ids).and_return( [lab_group_id] )
      BioanalyzerRun.find_for_user(@mock_user).should == [
        bioanalyzer_runs(:bioanalyzer_run_00001),
        bioanalyzer_runs(:bioanalyzer_run_00002)
      ]
    end
  end

  describe "converting to a pdf" do
    it "should create a pdf" do
      # import images
      BioanalyzerRun.import_new
      
      pdf = BioanalyzerRun.find(:last).to_pdf
      pdf.class.should == PDF::Writer
    end
  end
end
