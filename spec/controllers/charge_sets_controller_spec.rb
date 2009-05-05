require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChargeSetsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user

    LabGroup.stub!(:find).and_return( mock("Lab groups") )
  end
  
  describe "handling GET /charge_sets" do

    before(:each) do
      @charge_set = mock_model(ChargeSet)
      ChargeSet.stub!(:find).and_return([@charge_set])
      @mock_charge_periods = mock("Charge periods")
      ChargePeriod.stub!(:find).
        and_return(@mock_charge_periods)
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
  
    it "should find all charge_sets" do
      ChargeSet.should_receive(:find).with(:all).and_return([@charge_set])
      do_get
    end

    it "should find the 4 most recent charge periods" do
      ChargePeriod.should_receive(:find).
        with(:all, :order => "name DESC", :limit => 4).
        and_return(@mock_charge_periods)
      do_get
    end
  
    it "should assign the found charge_sets for the view" do
      do_get
      assigns[:charge_periods].should == @mock_charge_periods
    end
  end

  describe "handling GET /charge_sets.xml" do

    before(:each) do
      @charge_sets = mock("Array of ChargeSets", :to_xml => "XML")
      ChargeSet.stub!(:find).and_return(@charge_sets)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all charge_sets" do
      ChargeSet.should_receive(:find).with(:all).and_return(@charge_sets)
      do_get
    end
  
    it "should render the found charge_sets as xml" do
      @charge_sets.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /charge_sets/list_all" do

    before(:each) do
      @mock_charge_periods = mock("Charge periods")
      ChargePeriod.stub!(:find).
        and_return(@mock_charge_periods)
    end

    def do_get
      get :list_all
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find the all charge periods" do
      ChargePeriod.should_receive(:find).
        with(:all, :order => "name DESC").
        and_return(@mock_charge_periods)
      do_get
    end
  
    it "should assign the found charge_periods for the view" do
      do_get
      assigns[:charge_periods].should == @mock_charge_periods
    end
  end

  describe "handling GET /charge_sets/1.xml" do

    before(:each) do
      @charge_set = mock_model(ChargeSet, :to_xml => "XML")
      ChargeSet.stub!(:find).and_return(@charge_set)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the charge_set requested" do
      ChargeSet.should_receive(:find).with("1").and_return(@charge_set)
      do_get
    end
  
    it "should render the found charge_set as xml" do
      @charge_set.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /charge_sets/1.json" do

    before(:each) do
      @charge_set = mock_model(ChargeSet, :to_json => "JSON")
      ChargeSet.stub!(:find).and_return(@charge_set)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the charge_set requested" do
      ChargeSet.should_receive(:find).with("1").and_return(@charge_set)
      do_get
    end
  
    it "should render the found charge_set as json" do
      @charge_set.should_receive(:to_json).and_return("JSON")
      do_get
      response.body.should == "JSON"
    end
  end
  
  describe "handling GET /charge_sets/new" do

    before(:each) do
      @charge_set = mock_model(ChargeSet)
      ChargeSet.stub!(:new).and_return(@charge_set)
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
  
    it "should create an new charge_set" do
      ChargeSet.should_receive(:new).and_return(@charge_set)
      do_get
    end
  
    it "should not save the new charge_set" do
      @charge_set.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new charge_set for the view" do
      do_get
      assigns[:charge_set].should equal(@charge_set)
    end
  end

  describe "handling GET /charge_sets/1/edit" do

    before(:each) do
      @charge_set = mock_model(ChargeSet)
      ChargeSet.stub!(:find).and_return(@charge_set)
    end
  
    def do_get
      get :edit, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end
  
    it "should find the charge_set requested" do
      ChargeSet.should_receive(:find).and_return(@charge_set)
      do_get
    end
  
    it "should assign the found ChargeSet for the view" do
      do_get
      assigns[:charge_set].should equal(@charge_set)
    end
  end

  describe "handling POST /charge_sets" do

    before(:each) do
      @charge_set = mock_model(ChargeSet, :to_param => "1")
      ChargeSet.stub!(:new).and_return(@charge_set)
    end
    
    describe "with successful save" do
  
      def do_post
        @charge_set.should_receive(:save).and_return(true)
        post :create, :charge_set => {}
      end
  
      it "should create a new charge_set" do
        ChargeSet.should_receive(:new).with({}).and_return(@charge_set)
        do_post
      end

      it "should redirect to the charge_set index" do
        do_post
        response.should redirect_to(charge_sets_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @charge_set.should_receive(:save).and_return(false)
        post :create, :charge_set => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /charge_sets/1" do

    before(:each) do
      @charge_set = mock_model(ChargeSet, :to_param => "1")
      ChargeSet.stub!(:find).and_return(@charge_set)
    end
    
    describe "with successful update" do

      def do_put
        @charge_set.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the charge_set requested" do
        ChargeSet.should_receive(:find).with("1").and_return(@charge_set)
        do_put
      end

      it "should update the found charge_set" do
        do_put
        assigns(:charge_set).should equal(@charge_set)
      end

      it "should assign the found charge_set for the view" do
        do_put
        assigns(:charge_set).should equal(@charge_set)
      end

      it "should redirect to the charge_set index" do
        do_put
        response.should redirect_to(charge_sets_url)
      end

    end
    
    describe "with failed update" do

      def do_put
        @charge_set.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /charge_sets/1" do

    before(:each) do
      @charge_set = mock_model(ChargeSet, :destroy => true)
      ChargeSet.stub!(:find).and_return(@charge_set)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the charge_set requested" do
      ChargeSet.should_receive(:find).with("1").and_return(@charge_set)
      do_delete
    end
  
    it "should call destroy on the found charge_set" do
      @charge_set.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the charge_sets list" do
      do_delete
      response.should redirect_to(charge_sets_url)
    end
  end
end
