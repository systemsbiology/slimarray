require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BioanalyzerRunsController do
  include AuthenticatedSpecHelper

  describe "handling GET /bioanalyzer_runs" do

    before(:each) do
      login_as_user

      @bioanalyzer_run = mock_model(BioanalyzerRun)
      BioanalyzerRun.stub!(:find_for_user).and_return([@bioanalyzer_run])
    end
  
    def do_get
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find the bioanalyzer_runs for the user" do
      BioanalyzerRun.should_receive(:find_for_user).with(@current_user).and_return([@bioanalyzer_run])
      do_get
    end
  
    it "should assign the found bioanalyzer_runs for the view" do
      do_get
      assigns[:bioanalyzer_runs].should == [@bioanalyzer_run]
    end
  end

  describe "handling GET /bioanalyzer_runs/1" do

    before(:each) do
      @bioanalyzer_run = mock_model(BioanalyzerRun)
      @quality_traces = [ mock_model(QualityTrace) ]
      BioanalyzerRun.stub!(:find).and_return(@bioanalyzer_run)
      QualityTrace.stub!(:find).and_return(@quality_traces)
    end
  
    def do_get
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the bioanalyzer_run requested" do
      BioanalyzerRun.should_receive(:find).with("1").and_return(@bioanalyzer_run)
      do_get
    end
  
    it "should find the associated quality traces" do
      QualityTrace.should_receive(:find).with(
        :all,
        :conditions => ["bioanalyzer_run_id = ?", @bioanalyzer_run.id],
        :order => "number ASC"
      ).and_return(@quality_traces)
      do_get
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render show template" do
      do_get
      response.should render_template('show')
    end
  
    it "should assign the bioanalyzer_run for the view" do
      do_get
      assigns[:bioanalyzer_run].should == @bioanalyzer_run
    end

    it "should assign the quality_traces for the view" do
      do_get
      assigns[:quality_traces].should == @quality_traces
    end

  end

  describe "handling DELETE /bioanalyzer_runs/1" do

    before(:each) do
      @bioanalyzer_run = mock_model(BioanalyzerRun, :destroy => true)
      BioanalyzerRun.stub!(:find).and_return(@bioanalyzer_run)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the bioanalyzer_run requested" do
      BioanalyzerRun.should_receive(:find).with("1").and_return(@bioanalyzer_run)
      do_delete
    end
  
    it "should call destroy on the found bioanalyzer_run" do
      @bioanalyzer_run.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the bioanalyzer_runs list" do
      do_delete
      response.should redirect_to(bioanalyzer_runs_url)
    end
    
  end

  describe "handling GET /bioanalyzer_runs/1/pdf" do
    before(:each) do
      @bioanalyzer_run = mock_model(BioanalyzerRun, :name => "Run")
      BioanalyzerRun.stub!(:find).and_return(@bioanalyzer_run)
      @pdf = mock("PDF", :render => "Rendered PDF")
      @bioanalyzer_run.stub!(:to_pdf).and_return(@pdf)
    end

    def do_get
      get :pdf, :id => 1
    end

    it "should find the bioanalyzer_run" do
      BioanalyzerRun.should_receive(:find).with("1").and_return(@bioanalyzer_run)
      do_get
    end

    it "should convert the run to a pdf" do
      @bioanalyzer_run.should_receive(:to_pdf).and_return(@pdf)
      do_get
    end

    it "should send the pdf to the browser" do
      controller.should_receive(:send_data).with(
        "Rendered PDF",
        :filename => "Run.pdf",
        :type => "application/pdf"
      )
      do_get
    end
  end
end
