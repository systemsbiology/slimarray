require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HybridizationSetsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
  end

  describe "GET 'new'" do

    before(:each) do
      @available_samples = mock("Available Samples")
      Sample.should_receive(:find).with(
        :all,
        :conditions => [ "status = 'submitted'" ],
        :order => "id ASC"
      ).and_return(@available_samples)

      @hybridization_set = mock("Hybridization Set")
      HybridizationSet.should_receive(:new).and_return(@hybridization_set)
    end

    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render the new template" do
      do_get
      response.should render_template('new')
    end

    it "should assign the available samples to the view" do
      do_get
      assigns[:available_samples].should == @available_samples
    end

    it "should assign the new hybridization set to the view" do
      do_get
      assigns[:hybridization_set].should == @hybridization_set
    end

    it "should have an empty array for session hybridizations list" do
      do_get
      session[:hybridizations].should == []
    end

    it "should have nil as the session hybridization number" do
      do_get
      session[:hybridization_number].should be_nil
    end

  end

  describe "GET 'add'" do

    before(:each) do
      @new_hybridizations = [mock_model(Hybridization)]
      @hybridization_set = mock_model(HybridizationSet, :date => "2009-07-28",
                                     :valid? => true, :hybridizations => @new_hybridizations,
                                     :number => 1)
      HybridizationSet.should_receive(:new).with("these" => :params).and_return(@hybridization_set)
      Sample.should_receive(:available_to_hybridize).twice.and_return( mock("Samples" ) )
    end

    def do_get
      get :add, :hybridization_set => {"these" => :params}
    end

    describe "without existing hybridizations" do

      before(:each) do
        session[:hybridizations] = Array.new
        session[:hybridization_number] = nil
      end

      it "should be successful" do
        do_get
        response.should be_success
      end

      it "should have session hybridizations consisting only of those that were newly created" do
        do_get
        session[:hybridizations].should == @new_hybridizations
      end

      it "should set the session hyb number to the number of newly created hybridizations" do
        do_get
        session[:hybridization_number].should == 1
      end
    end

    describe "with existing hybridizations" do

      before(:each) do
        @old_hybridization = mock_model(Hybridization)
        session[:hybridizations] = [ @old_hybridization ]
        session[:hybridization_number] = 1
      end

      it "should be successful" do
        do_get
        response.should be_success
      end

      it "should have session hybridizations consisting of the old plus new ones" do
        do_get
        session[:hybridizations].should == [ @old_hybridization ] + @new_hybridizations
      end

      it "should set the session hyb number to the number of old plus new ones" do
        do_get
        session[:hybridization_number].should == 2
      end
    end

  end

  describe "GET 'create'" do
  end
end
