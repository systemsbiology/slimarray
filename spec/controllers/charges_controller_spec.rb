require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChargesController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user

    @charge_set = mock_model(ChargeSet)
    ChargeSet.should_receive(:find).with("42").and_return(@charge_set)
  end
  
  describe "handling GET /charges" do

    before(:each) do
      @charge = mock_model(Charge)
      @charges = mock("Charges", :find => [@charge])
      @charge_set.stub!(:charges).and_return(@charges)
    end
  
    def do_get
      get :index, :charge_set_id => 42
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find all charges under the charge set" do
      @charge_set.should_receive(:charges).and_return(@charges)
      @charges.should_receive(:find).with(:all, :order => "date ASC, description ASC").and_return([@charge])
      do_get
    end
  
    it "should assign the found charges for the view" do
      do_get
      assigns[:charges].should == [@charge]
    end
  end

  describe "handling GET /charges.xml" do

    before(:each) do
      @charges_sorted = mock("Sorted Charges", :to_xml => "XML")
      @charges = mock("Charges", :find => @charges_sorted)
      @charge_set.stub!(:charges).and_return(@charges)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index, :charge_set_id => 42
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all charges under the charge set" do
      @charge_set.should_receive(:charges).and_return(@charges)
      @charges.should_receive(:find).with(:all, :order => "date ASC, description ASC").and_return(@charges_sorted)
      do_get
    end
  
    it "should render the found charges as xml" do
      do_get
      response.body.should == "XML"
    end

  end

  describe "handling GET /charges.json" do

    before(:each) do
      @charges_sorted = mock("Sorted Charges", :to_json => "JSON")
      @charges = mock("Charges", :find => @charges_sorted)
      @charge_set.stub!(:charges).and_return(@charges)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :index, :charge_set_id => 42
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all charges under the charge set" do
      @charge_set.should_receive(:charges).and_return(@charges)
      @charges.should_receive(:find).with(:all, :order => "date ASC, description ASC").and_return(@charges_sorted)
      do_get
    end
  
    it "should render the found charges as json" do
      do_get
      response.body.should == "JSON"
    end

  end

  describe "handling GET /charges/1.xml" do

    before(:each) do
      @charge = mock_model(Charge, :to_xml => "XML")
      @charges = mock("Charges", :find => @charges_sorted)
      @charge_set.stub!(:charges).and_return(@charges)
      @charges.stub!(:find).and_return(@charge)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1", :charge_set_id => 42
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the charge requested" do
      @charge_set.should_receive(:charges).and_return(@charges)
      @charges.should_receive(:find).with("1").and_return(@charge)
      do_get
    end
  
    it "should render the found charge as xml" do
      @charge.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end

  end

  describe "handling GET /charges/1.json" do

    before(:each) do
      @charge = mock_model(Charge, :to_json => "JSON")
      @charges = mock("Charges")
      @charge_set.stub!(:charges).and_return(@charges)
      @charges.stub!(:find).and_return(@charge)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :show, :id => "1", :charge_set_id => 42
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the charge requested" do
      @charge_set.should_receive(:charges).and_return(@charges)
      @charges.should_receive(:find).with("1").and_return(@charge)
      do_get
    end
  
    it "should render the found charge as json" do
      @charge.should_receive(:to_json).and_return("JSON")
      do_get
      response.body.should == "JSON"
    end
  end
  
  describe "handling GET /charges/new" do

    before(:each) do
      @charge = mock_model(Charge)
      @charges = mock("Charges")
      Charge.stub!(:from_template_id).and_return(@charge)
      @charge_templates = mock("Charge templates")
      ChargeTemplate.should_receive(:find).
        with(:all, :order => "name ASC").
        and_return(@charge_templates)
    end
  
    def do_get(format = "text/html")
      @request.env["HTTP_ACCEPT"] = format
      get :new, :charge_set_id => 42, :charge_template_id => 12
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should create an new charge" do
      Charge.should_receive(:from_template_id).
        with("12", @charge_set).
        and_return(@charge)
      do_get
    end
  
    it "should not save the new charge" do
      @charge.should_not_receive(:save)
      do_get
    end
  
    context "with an HTML response" do

      it "should render new template" do
        do_get
        response.should render_template('new')
      end
    
      it "should assign the new charge for the view" do
        do_get
        assigns[:charge].should equal(@charge)
      end

      it "should assign the charge templates to the view" do
        do_get
        assigns[:charge_templates].should equal(@charge_templates)
      end

    end

    it "should render the new charge as XML for an XML response" do
      @charge.should_receive(:to_xml).and_return("XML")
      do_get(format = "application/xml")
      response.body.should == "XML"
    end

    it "should render the new charge as JSON for an JSON response" do
      @charge.should_receive(:to_json).and_return("JSON")
      do_get(format = "application/json")
      response.body.should == "JSON"
    end

  end

  describe "handling GET /charges/new" do
    
    it "should call the 'new' action" do
      controller.should_receive(:new)
      get :new_from_template, :charge_set_id => 42
    end

  end

  describe "handling GET /charges/1/edit" do

    before(:each) do
      @charge = mock_model(Charge)
      @charges = mock("Charges", :find => @charges_sorted)
      @charge_set.stub!(:charges).and_return(@charges)
      @charges.stub!(:find).and_return(@charge)
    end
  
    def do_get(format = "text/html")
      @request.env["HTTP_ACCEPT"] = format
      get :edit, :id => "1", :charge_set_id => 42
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the charge requested" do
      @charge_set.should_receive(:charges).and_return(@charges)
      @charges.should_receive(:find).and_return(@charge)
      do_get
    end
  
    context "with an HTML response" do

      it "should render edit template" do
        do_get
        response.should render_template('edit')
      end
    
      it "should assign the found Charge for the view" do
        do_get
        assigns[:charge].should equal(@charge)
      end

    end

    it "should render the charge as XML for an XML response" do
      @charge.should_receive(:to_xml).and_return("XML")
      do_get(format = "application/xml")
      response.body.should == "XML"
    end

    it "should render the charge as JSON for an JSON response" do
      @charge.should_receive(:to_json).and_return("JSON")
      do_get(format = "application/json")
      response.body.should == "JSON"
    end

  end

  describe "handling POST /charges" do

    before(:each) do
      @charge = mock_model(Charge, :to_param => "1")
      @charges = mock("Charges", :find => @charges_sorted)
      @charge_set.stub!(:charges).and_return(@charges)
      @charges.stub!(:new).and_return(@charge)
    end
    
    describe "with successful save" do
  
      def do_post(format = "text/html")
        @charge.should_receive(:save).and_return(true)
        @request.env["HTTP_ACCEPT"] = format
        post :create, :charge => {}, :charge_set_id => 42
      end
  
      it "should create a new charge" do
        @charge_set.should_receive(:charges).and_return(@charges)
        @charges.should_receive(:new).and_return(@charge)
        do_post
      end

      it "should redirect to the charge index with an HTML response" do
        do_post
        response.should redirect_to( charge_set_charges_url(@charge_set) )
      end

      it "should render the charge as XML with an XML repsonse" do
        @charge.should_receive(:to_xml).and_return("XML")
        do_post(format = "application/xml")
        response.body.should == "XML"
      end
      
      it "should render the charge as JSON with a JSON repsonse" do
        @charge.should_receive(:to_json).and_return("JSON")
        do_post(format = "application/json")
        response.body.should == "JSON"
      end

    end
    
    describe "with failed save" do

      def do_post(format = "text/html")
        @charge.should_receive(:save).and_return(false)
        @request.env["HTTP_ACCEPT"] = format
        post :create, :charge => {}, :charge_set_id => 42
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end

      it "should render the new action with an HTML response" do
        do_post
        response.should render_template('new')
      end

      it "should render the errors in XML with an XML response" do
        @errors = mock("Save errors", :to_xml => "XML")
        @charge.should_receive(:errors).and_return(@errors)
        do_post(format = "application/xml")
        response.body.should == "XML"
      end
      
      it "should render the errors in JSON with a JSON response" do
        @errors = mock("Save errors", :to_json => "JSON")
        @charge.should_receive(:errors).and_return(@errors)
        do_post(format = "application/json")
        response.body.should == "JSON"
      end
      
    end
  end

  describe "handling PUT /charges/1" do

    before(:each) do
      @charge = mock_model(Charge, :to_param => "1")
      @charges = mock("Charges", :find => @charges_sorted)
      @charge_set.stub!(:charges).and_return(@charges)
      @charges.stub!(:find).and_return(@charge)
    end
    
    describe "with successful update" do

      def do_put(format = "text/html")
        @request.env["HTTP_ACCEPT"] = format
        @charge.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1", :charge_set_id => 42
      end

      it "should find the charge requested" do
        @charges.should_receive(:find).with("1").and_return(@charge)
        do_put
      end

      it "should update the found charge" do
        do_put
        assigns(:charge).should equal(@charge)
      end

      it "should redirect to the charge index for an HTML response" do
        do_put
        response.should redirect_to( charge_set_charges_url(@charge_set) )
      end

      it "should provide a successful XML response" do
        do_put(format = "application/xml")
        response.should be_success
      end

      it "should provide a successful JSON response" do
        do_put(format = "application/json")
        response.should be_success
      end

    end
    
    describe "with failed update" do

      def do_put(format = "text/html")
        @request.env["HTTP_ACCEPT"] = format
        @charge.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1", :charge_set_id => 42
      end

      it "should re-render 'edit' with an HTML response" do
        do_put
        response.should render_template('edit')
      end

      it "should render the errors in XML with an XML response" do
        @errors = mock("Save errors", :to_xml => "XML")
        @charge.should_receive(:errors).and_return(@errors)
        do_put(format = "application/xml")
        response.body.should == "XML"
      end
      
      it "should render the errors in JSON with a JSON response" do
        @errors = mock("Save errors", :to_json => "JSON")
        @charge.should_receive(:errors).and_return(@errors)
        do_put(format = "application/json")
        response.body.should == "JSON"
      end
    end
  end

  describe "handling DELETE /charges/1" do

    before(:each) do
      @charge = mock_model(Charge, :destroy => true)
      @charges = mock("Charges", :find => @charges_sorted)
      @charge_set.stub!(:charges).and_return(@charges)
      @charges.stub!(:find).and_return(@charge)
    end
  
    def do_delete(format = "text/html")
      @request.env["HTTP_ACCEPT"] = format
      delete :destroy, :id => "1", :charge_set_id => 42
    end

    it "should find the charge requested" do
      @charges.should_receive(:find).and_return(@charge)
      do_delete
    end
  
    it "should call destroy on the found charge" do
      @charge.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the charges list with an HTML response" do
      do_delete
      response.should redirect_to( charge_set_charges_url(@charge_set) )
    end

    it "should provide a successful XML response" do
      do_delete(format = "application/xml")
      response.should be_success
    end

    it "should provide a successful JSON response" do
      do_delete(format = "application/json")
      response.should be_success
    end

  end

end
