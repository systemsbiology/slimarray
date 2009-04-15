require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OrganismsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
  end
  
  describe "handling GET /organisms" do

    before(:each) do
      @organism = mock_model(Organism)
      Organism.stub!(:find).and_return([@organism])
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
  
    it "should find all organisms" do
      Organism.should_receive(:find).with(:all, :order => "name ASC").and_return([@organism])
      do_get
    end
  
    it "should assign the found organisms for the view" do
      do_get
      assigns[:organisms].should == [@organism]
    end
  end

  describe "handling GET /organisms.xml" do

    before(:each) do
      @organisms = mock("Array of Organisms", :to_xml => "XML")
      Organism.stub!(:find).and_return(@organisms)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all organisms" do
      Organism.should_receive(:find).with(:all, :order => "name ASC").and_return(@organisms)
      do_get
    end
  
    it "should render the found organisms as xml" do
      @organisms.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /organisms/1.xml" do

    before(:each) do
      @organism = mock_model(Organism, :to_xml => "XML")
      Organism.stub!(:find).and_return(@organism)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the organism requested" do
      Organism.should_receive(:find).with("1").and_return(@organism)
      do_get
    end
  
    it "should render the found organism as xml" do
      @organism.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /organisms/1.json" do

    before(:each) do
      @organism = mock_model(Organism, :to_json => "JSON")
      Organism.stub!(:find).and_return(@organism)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the organism requested" do
      Organism.should_receive(:find).with("1").and_return(@organism)
      do_get
    end
  
    it "should render the found organism as json" do
      @organism.should_receive(:to_json).and_return("JSON")
      do_get
      response.body.should == "JSON"
    end
  end
  
  describe "handling GET /organisms/new" do

    before(:each) do
      @organism = mock_model(Organism)
      Organism.stub!(:new).and_return(@organism)
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
  
    it "should create an new organism" do
      Organism.should_receive(:new).and_return(@organism)
      do_get
    end
  
    it "should not save the new organism" do
      @organism.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new organism for the view" do
      do_get
      assigns[:organism].should equal(@organism)
    end
  end

  describe "handling GET /organisms/1/edit" do

    before(:each) do
      @organism = mock_model(Organism)
      Organism.stub!(:find).and_return(@organism)
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
  
    it "should find the organism requested" do
      Organism.should_receive(:find).and_return(@organism)
      do_get
    end
  
    it "should assign the found Organism for the view" do
      do_get
      assigns[:organism].should equal(@organism)
    end
  end

  describe "handling POST /organisms" do

    before(:each) do
      @organism = mock_model(Organism, :to_param => "1")
      Organism.stub!(:new).and_return(@organism)
    end
    
    describe "with successful save" do
  
      def do_post
        @organism.should_receive(:save).and_return(true)
        post :create, :organism => {}
      end
  
      it "should create a new organism" do
        Organism.should_receive(:new).with({}).and_return(@organism)
        do_post
      end

      it "should redirect to the organism index" do
        do_post
        response.should redirect_to(organisms_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @organism.should_receive(:save).and_return(false)
        post :create, :organism => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /organisms/1" do

    before(:each) do
      @organism = mock_model(Organism, :to_param => "1")
      Organism.stub!(:find).and_return(@organism)
    end
    
    describe "with successful update" do

      def do_put
        @organism.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the organism requested" do
        Organism.should_receive(:find).with("1").and_return(@organism)
        do_put
      end

      it "should update the found organism" do
        do_put
        assigns(:organism).should equal(@organism)
      end

      it "should assign the found organism for the view" do
        do_put
        assigns(:organism).should equal(@organism)
      end

      it "should redirect to the organism index" do
        do_put
        response.should redirect_to(organisms_url)
      end

    end
    
    describe "with failed update" do

      def do_put
        @organism.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /organisms/1" do

    before(:each) do
      @organism = mock_model(Organism, :destroy => true)
      Organism.stub!(:find).and_return(@organism)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the organism requested" do
      Organism.should_receive(:find).with("1").and_return(@organism)
      do_delete
    end
  
    it "should call destroy on the found organism" do
      @organism.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the organisms list" do
      do_delete
      response.should redirect_to(organisms_url)
    end
  end
end
