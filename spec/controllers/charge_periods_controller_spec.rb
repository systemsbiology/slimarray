require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChargePeriodsController do
  include AuthenticatedSpecHelper

  describe "handling GET /charge_periods/new" do

    before(:each) do
      @charge_period = mock_model(ChargePeriod)
      ChargePeriod.stub!(:new).and_return(@charge_period)
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
  
    it "should create an new charge_period" do
      ChargePeriod.should_receive(:new).and_return(@charge_period)
      do_get
    end
  
    it "should not save the new charge_period" do
      @charge_period.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new charge_period for the view" do
      do_get
      assigns[:charge_period].should equal(@charge_period)
    end
  end

  describe "handling GET /charge_periods/1/edit" do

    before(:each) do
      @charge_period = mock_model(ChargePeriod)
      ChargePeriod.stub!(:find).and_return(@charge_period)
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
  
    it "should find the charge_period requested" do
      ChargePeriod.should_receive(:find).and_return(@charge_period)
      do_get
    end
  
    it "should assign the found ChargePeriod for the view" do
      do_get
      assigns[:charge_period].should equal(@charge_period)
    end
  end

  describe "handling POST /charge_periods" do

    before(:each) do
      @charge_period = mock_model(ChargePeriod, :to_param => "1")
      ChargePeriod.stub!(:new).and_return(@charge_period)
    end
    
    describe "with successful save" do
  
      def do_post
        @charge_period.should_receive(:save).and_return(true)
        post :create, :charge_period => {}
      end
  
      it "should create a new charge_period" do
        ChargePeriod.should_receive(:new).with({}).and_return(@charge_period)
        do_post
      end

      it "should redirect to the charge_period index" do
        do_post
        response.should redirect_to(charge_sets_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @charge_period.should_receive(:save).and_return(false)
        post :create, :charge_period => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /charge_periods/1" do

    before(:each) do
      @charge_period = mock_model(ChargePeriod, :to_param => "1")
      ChargePeriod.stub!(:find).and_return(@charge_period)
    end
    
    describe "with successful update" do

      def do_put
        @charge_period.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the charge_period requested" do
        ChargePeriod.should_receive(:find).with("1").and_return(@charge_period)
        do_put
      end

      it "should update the found charge_period" do
        do_put
        assigns(:charge_period).should equal(@charge_period)
      end

      it "should assign the found charge_period for the view" do
        do_put
        assigns(:charge_period).should equal(@charge_period)
      end

      it "should redirect to the charge_period index" do
        do_put
        response.should redirect_to(charge_sets_url)
      end

    end
    
    describe "with failed update" do

      def do_put
        @charge_period.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /charge_periods/1" do

    before(:each) do
      @charge_period = mock_model(ChargePeriod, :destroy => true)
      ChargePeriod.stub!(:find).and_return(@charge_period)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the charge_period requested" do
      ChargePeriod.should_receive(:find).with("1").and_return(@charge_period)
      do_delete
    end
  
    it "should call destroy on the found charge_period" do
      @charge_period.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the charge_periods list" do
      do_delete
      response.should redirect_to(charge_sets_url)
    end
  end

  describe "handling GET /charge_periods/1/pdf" do
    before(:each) do
      @charge_period = mock_model(ChargePeriod, :name => "Monthly Charges")
      ChargePeriod.stub!(:find).and_return(@charge_period)
      @pdf = mock("PDF", :render => "Rendered PDF")
      @charge_period.stub!(:to_pdf).and_return(@pdf)
    end

    def do_get
      get :pdf, :id => 1
    end

    it "should find the charge_period" do
      ChargePeriod.should_receive(:find).with("1").and_return(@charge_period)
      do_get
    end

    it "should convert the run to a pdf" do
      @charge_period.should_receive(:to_pdf).and_return(@pdf)
      do_get
    end

    it "should send the pdf to the browser" do
      controller.should_receive(:send_data).with(
        "Rendered PDF",
        :filename => "charges_Monthly Charges.pdf",
        :type => "application/pdf"
      )
      do_get
    end
  end

  describe "handling GET /charge_periods/1/excel" do
    before(:each) do
      @charge_period = mock_model(ChargePeriod, :name => "Monthly Charges")
      ChargePeriod.stub!(:find).and_return(@charge_period)
      @excel_file = "excel_file"
      @charge_period.stub!(:to_excel).and_return(@excel_file)
      controller.stub!(:send_file)
    end

    def do_get
      get :excel, :id => 1
    end

    it "should find the charge_period" do
      ChargePeriod.should_receive(:find).with("1").and_return(@charge_period)
      do_get
    end

    it "should convert the run to an Excel file" do
      @charge_period.should_receive(:to_excel).and_return(@excel_file)
      do_get
    end

    it "should send the Excel file to the browser" do
      controller.should_receive(:send_file).with( @excel_file )
      do_get
    end
  end
end
