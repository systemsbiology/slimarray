require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChargeTemplatesController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff
  end
  
  describe "handling GET /charge_templates" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate)
      ChargeTemplate.stub!(:find).and_return([@charge_template])
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
  
    it "should find all charge_templates" do
      ChargeTemplate.should_receive(:find).with(:all, :order => "name ASC").and_return([@charge_template])
      do_get
    end
  
    it "should assign the found charge_templates for the view" do
      do_get
      assigns[:charge_templates].should == [@charge_template]
    end
  end

  describe "handling GET /charge_templates.xml" do

    before(:each) do
      @charge_templates = mock("Array of ChargeTemplates", :to_xml => "XML")
      ChargeTemplate.stub!(:find).and_return(@charge_templates)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all charge_templates" do
      ChargeTemplate.should_receive(:find).with(:all, :order => "name ASC").and_return(@charge_templates)
      do_get
    end
  
    it "should render the found charge_templates as xml" do
      @charge_templates.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /charge_templates/1.xml" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate, :to_xml => "XML")
      ChargeTemplate.stub!(:find).and_return(@charge_template)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the charge_template requested" do
      ChargeTemplate.should_receive(:find).with("1").and_return(@charge_template)
      do_get
    end
  
    it "should render the found charge_template as xml" do
      @charge_template.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /charge_templates/1.json" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate, :to_json => "JSON")
      ChargeTemplate.stub!(:find).and_return(@charge_template)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the charge_template requested" do
      ChargeTemplate.should_receive(:find).with("1").and_return(@charge_template)
      do_get
    end
  
    it "should render the found charge_template as json" do
      @charge_template.should_receive(:to_json).and_return("JSON")
      do_get
      response.body.should == "JSON"
    end
  end
  
  describe "handling GET /charge_templates/new" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate)
      ChargeTemplate.stub!(:new).and_return(@charge_template)
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
  
    it "should create an new charge_template" do
      ChargeTemplate.should_receive(:new).and_return(@charge_template)
      do_get
    end
  
    it "should not save the new charge_template" do
      @charge_template.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new charge_template for the view" do
      do_get
      assigns[:charge_template].should equal(@charge_template)
    end
  end

  describe "handling GET /charge_templates/1/edit" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate)
      ChargeTemplate.stub!(:find).and_return(@charge_template)
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
  
    it "should find the charge_template requested" do
      ChargeTemplate.should_receive(:find).and_return(@charge_template)
      do_get
    end
  
    it "should assign the found ChargeTemplate for the view" do
      do_get
      assigns[:charge_template].should equal(@charge_template)
    end
  end

  describe "handling POST /charge_templates" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate, :to_param => "1")
      ChargeTemplate.stub!(:new).and_return(@charge_template)
    end
    
    describe "with successful save" do
  
      def do_post
        @charge_template.should_receive(:save).and_return(true)
        post :create, :charge_template => {}
      end
  
      it "should create a new charge_template" do
        ChargeTemplate.should_receive(:new).with({}).and_return(@charge_template)
        do_post
      end

      it "should redirect to the charge_template index" do
        do_post
        response.should redirect_to(charge_templates_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @charge_template.should_receive(:save).and_return(false)
        post :create, :charge_template => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /charge_templates/1" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate, :to_param => "1")
      ChargeTemplate.stub!(:find).and_return(@charge_template)
    end
    
    describe "with successful update" do

      def do_put
        @charge_template.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the charge_template requested" do
        ChargeTemplate.should_receive(:find).with("1").and_return(@charge_template)
        do_put
      end

      it "should update the found charge_template" do
        do_put
        assigns(:charge_template).should equal(@charge_template)
      end

      it "should assign the found charge_template for the view" do
        do_put
        assigns(:charge_template).should equal(@charge_template)
      end

      it "should redirect to the charge_template index" do
        do_put
        response.should redirect_to(charge_templates_url)
      end

    end
    
    describe "with failed update" do

      def do_put
        @charge_template.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /charge_templates/1" do

    before(:each) do
      @charge_template = mock_model(ChargeTemplate, :destroy => true)
      ChargeTemplate.stub!(:find).and_return(@charge_template)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the charge_template requested" do
      ChargeTemplate.should_receive(:find).with("1").and_return(@charge_template)
      do_delete
    end
  
    it "should call destroy on the found charge_template" do
      @charge_template.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the charge_templates list" do
      do_delete
      response.should redirect_to(charge_templates_url)
    end
  end
end
