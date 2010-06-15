require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleSetsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
    
    projects = [mock_model(Project), mock_model(Project)]
    Project.stub!(:accessible_to_user).and_return(projects)
    NamingScheme.stub!(:find).and_return(
      [mock_model(NamingScheme), mock_model(NamingScheme)]
    )
    ChipType.stub!(:find).and_return(
      [mock_model(ChipType), mock_model(ChipType)]
    )
  end
    
  describe "handling GET /sample_sets/new" do
    describe "step 1" do
      before(:each) do
        @sample_set = mock_model(SampleSet)
        SampleSet.stub!(:new).and_return(@sample_set)
      end

      def do_get
        get :new
      end

      it "should be successful" do
        do_get
        response.should be_success
      end

      it "should render new template" do
        do_get
        response.should render_template('new')
      end

      it "should create an new sample_set" do
        SampleSet.should_receive(:new).and_return(@sample_set)
        do_get
      end

      it "should not save the new sample_set" do
        @sample_set.should_not_receive(:save)
        do_get
      end

      it "should assign the new sample_set for the view" do
        do_get
        assigns[:sample_set].should equal(@sample_set)
      end      
    end
    
    describe "step 2" do
      before(:each) do
        @sample_set = mock_model(SampleSet)
        SampleSet.stub!(:new).and_return(@sample_set)
      end
      
      def do_get
        get :new, :step => "2", :sample_set => { :number_of_samples => 2 }
      end
      
      describe "with invalid sample set data" do
        before(:each) do
          @sample_set.stub!(:valid?).and_return(false)
        end
        
        it "should create an new sample_set" do
          SampleSet.should_receive(:new).and_return(@sample_set)
          do_get
        end
        
        it "should check the validity of the sample set" do
          @sample_set.should_receive(:valid?).and_return(false)
          do_get
        end
        
        it "should be successful" do
          do_get
          response.should be_success
        end

        it "should render new template" do
          do_get
          response.should render_template('new')
        end
      end
      
      describe "with valid sample set data" do
        before(:each) do
          @lab_group_profile = mock_model(LabGroupProfile, :samples_need_approval => true)
          @lab_group = mock_model(LabGroup, :lab_group_profile => @lab_group_profile) 
          @project = mock_model(Project, :lab_group => @lab_group)
          @chip_type = mock_model(ChipType, :organism_id => 5)
          @sample_set.stub!(:valid?).and_return(true)
          @sample_set.stub!(:submission_date).and_return('2008-02-01')
          @sample_set.stub!(:project_id).and_return(1)
          @sample_set.stub!(:chip_type_id).and_return(1)
          @sample_set.stub!(:chip_type).and_return(@chip_type)
          @sample_set.stub!(:project).and_return(@project)
          @sample_set.stub!(:sbeams_user).and_return("jsmith")
          @sample_set.stub!(:label_id).and_return(2)
          @sample = mock_model(Sample)
          @sample.stub!(:populate_default_visibilities_and_texts)
          Sample.stub!(:new).and_return( @sample )
        end

        describe "without a naming scheme" do
          before(:each) do
            @sample_set.stub!(:naming_scheme).and_return(nil)
            @sample_set.stub!(:naming_scheme_id).and_return(nil)
          end

          it "should create an new sample_set" do
            SampleSet.should_receive(:new).and_return(@sample_set)
            do_get
          end
          
          it "should check the validity of the sample set" do
            @sample_set.should_receive(:valid?).and_return(true)
            do_get
          end

          it "should be successful" do
            do_get
            response.should be_success
          end

          it "should render new template" do
            do_get
            response.should render_template('new')
          end

          it "should not save the new sample_set" do
            @sample_set.should_not_receive(:save)
            do_get
          end

          it "should assign the new sample_set for the view" do
            do_get
            assigns[:sample_set].should equal(@sample_set)
          end
        end

        describe "with a naming scheme" do
          before(:each) do
            @naming_scheme = mock_model(NamingScheme)
            @sample_set.stub!(:naming_scheme).and_return(@naming_scheme)
            @sample_set.stub!(:naming_scheme_id).and_return(1)
            @naming_scheme.stub!(:ordered_naming_elements).and_return(
              [mock_model(NamingElement), mock_model(NamingElement)]
            )
            NamingScheme.stub!(:find).and_return(nil)
          end
          
          it "should create an new sample_set" do
            SampleSet.should_receive(:new).and_return(@sample_set)
            do_get
          end
          
          it "should check the validity of the sample set" do
            @sample_set.should_receive(:valid?).and_return(true)
            do_get
          end

          it "should be successful" do
            do_get
            response.should be_success
          end

          it "should render new template" do
            do_get
            response.should render_template('new')
          end

          it "should not save the new sample_set" do
            @sample_set.should_not_receive(:save)
            do_get
          end

          it "should assign the new sample_set for the view" do
            do_get
            assigns[:sample_set].should equal(@sample_set)
          end
        end
      end
    end
  end
  
  describe "handling POST /sample_sets" do
    before(:each) do
      @lab_group = mock_model(LabGroup)
      @project = mock_model(Project, :lab_group => @lab_group)
      @sample_set = mock_model(SampleSet, :to_param => "1", :project => @project)
      SampleSet.stub!(:new).and_return(@sample_set)
      @sample = mock_model(Sample)
      Sample.stub!(:new).and_return(@sample)
      @sample_set.stub!(:samples=).and_return(true)
      Notifier.stub!(:deliver_sample_submission_notification)
    end
   
    describe "with a valid sample set" do
      before(:each) do
        @sample_set.stub!(:valid?).and_return(true)
        @sample_set.stub!(:save).and_return(true)
        @sample.stub!(:save).and_return(true)
      end
  
      def do_post
        post :create,
          :sample_set => {"submission_date(2i)"=>"10", "naming_scheme_id"=>"",
                          "number_of_samples"=>"2", "submission_date(3i)"=>"6",
                          "submission_date(1i)"=>"2008"},
           :sample => {"0"=>{"status"=>"", "chip_type_id"=>"1",
             "short_sample_name"=>"1121", "schemed_name"=>{"Protocol"=>"203",
            "Cell Type"=>"197", "Time"=>"184",
             "Biological Replicate"=>"", "Antibody"=>"291", "Stimulus"=>"189",
             "Exclude From Analysis"=>"204", "Technical Replicate"=>"202", "Date"=>""},
             "submission_date"=>"2008-10-02"} }
      end
  
      it "should create a new sample_set" do
        SampleSet.should_receive(:new).and_return(@sample_set)
        do_post
      end
      
      it "should find the new sample set valid" do
        @sample_set.should_receive(:valid?).and_return(true)
        do_post
      end
      
      it "should save the sample" do
        @sample.should_receive(:save).and_return(true)
        do_post
      end      

      it "should redirect to the list of samples" do
        do_post
        response.should redirect_to("/")
      end
      
      it "should send email notifications" do
        Notifier.should_receive(:deliver_sample_submission_notification).
          with([@sample])
        do_post
      end
    end
    
    describe "with an invalid sample set" do
      before(:each) do
        @sample_set.stub!(:valid?).and_return(false)
        @naming_scheme = mock_model(NamingScheme)
        @sample_set.stub!(:naming_scheme).and_return(@naming_scheme)
        @naming_scheme.stub!(:ordered_naming_elements).and_return( [mock_model(NamingElement)] )
      end

      def do_post
        post :create,
          :sample_set => {"submission_date(2i)"=>"10", "naming_scheme_id"=>"",
                          "number_of_samples"=>"2", "submission_date(3i)"=>"6",
                          "submission_date(1i)"=>"2008"},
           :sample => {"0"=>{"status"=>"", "chip_type_id"=>"1",
             "short_sample_name"=>"1121", "schemed_name"=>{"Protocol"=>"203",
            "Cell Type"=>"197", "Time"=>"184",
             "Biological Replicate"=>"", "Antibody"=>"291", "Stimulus"=>"189",
             "Exclude From Analysis"=>"204", "Technical Replicate"=>"202", "Date"=>""},
             "submission_date"=>"2008-10-02"} }
      end

      it "should find the new sample set invalid" do
        @sample_set.should_receive(:valid?).and_return(false)
        do_post
      end

      it "should get the naming scheme for the sample set" do
        @sample_set.should_receive(:naming_scheme).and_return(@naming_scheme)
        do_post
      end
      
      it "should get the naming elements for the naming scheme" do
        @naming_scheme.should_receive(:ordered_naming_elements).and_return( [mock_model(NamingElement)] )
        do_post
      end
      
      it "should set the step parameter to go to step 2" do
        do_post
        params[:step].should == "2"
      end
  
      it "should re-render 'new' template at step 2" do
        do_post
        response.should render_template('new')
      end
    end
  end
end
