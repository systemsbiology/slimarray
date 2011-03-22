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
    @chip_type = mock_model(ChipType)
    ChipType.stub!(:find).and_return(
      [mock_model(ChipType), @chip_type]
    )
    @chip_type.stub!(:service_options).and_return( mock("Service Options") )
  end
    
  describe "handling GET /sample_sets/new" do
    it "should render new template" do
      get 'new'
      response.should render_template('new')
    end
  end
  
  describe "handling POST /sample_sets" do
    before(:each) do
      @sample_set = mock_model(SampleSet, :to_param => "1")
      SampleSet.stub!(:parse_api).and_return(@sample_set)
    end

    def do_post
      post :create, :sample_set => {:some => "param"}
    end
   
    describe "with a successful save" do
      before(:each) do
        @sample_set.stub!(:save).and_return(true)
      end
  
      it "parses the parameters to make a new sample set" do
        SampleSet.should_receive(:parse_api).
          with({"some" => "param", "submitted_by" => @current_user.login}).
          and_return(@sample_set)
        do_post
      end
      
      it "should save the sample set" do
        @sample_set.should_receive(:save).and_return(true)
        do_post
      end      

      it "should provide a JSON success message" do
        do_post
        response.body.should =~ /[{\"message\":\s*Samples recorded}]/
      end
    end
    
    describe "with a failed save" do
      before(:each) do
        @sample_set.stub!(:save).and_return(false)
        @sample_set.stub!(:error_message).and_return("Major problem")
      end

      it "parses the parameters to make a new sample set" do
        SampleSet.should_receive(:parse_api).
          with({"some" => "param", "submitted_by" => @current_user.login}).
          and_return(@sample_set)
        do_post
      end
      
      it "should fail to save the sample set" do
        @sample_set.should_receive(:save).and_return(false)
        do_post
      end      

      it "should provide a JSON error message" do
        do_post
        response.body.should =~ /[{\"message\":\s*Major problemx}]/
      end
    end
  end
end
