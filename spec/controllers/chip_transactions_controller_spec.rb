require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChipTransactionsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff
  end
  
  describe "handling GET /chip_transactions" do

    before(:each) do
      @lab_group = mock_model(LabGroup)
      LabGroup.should_receive(:find).with("42").and_return(@lab_group)
      @chip_type = mock_model(ChipType)
      ChipType.should_receive(:find).with("23").and_return(@chip_type)

      @chip_transactions = mock("Chip Transactions")
      ChipTransaction.should_receive(:find_all_in_lab_group_chip_type).
        with(@lab_group.id, @chip_type.id).and_return(@chip_transactions)
      @totals = mock("Chip inventory totals")
      ChipTransaction.should_receive(:get_chip_totals).with(@chip_transactions).
        and_return(@totals)
    end
  
    def do_get
      get :index, :chip_type_id => 23, :lab_group_id => 42
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('list')
    end
  
    it "should assign the found chip_transactions for the view" do
      do_get
      assigns[:chip_transactions].should == @chip_transactions
    end
  end

  describe "handling GET /chip_transactions.xml" do

    before(:each) do
      @chip_transactions = mock("Chip Transactions", :to_xml => "XML")
      @lab_group = mock_model(LabGroup)
      LabGroup.should_receive(:find).with("42").and_return(@lab_group)
      @chip_type = mock_model(ChipType)
      ChipType.should_receive(:find).with("23").and_return(@chip_type)

      ChipTransaction.should_receive(:find_all_in_lab_group_chip_type).
        with(@lab_group.id, @chip_type.id).and_return(@chip_transactions)
      @totals = mock("Chip inventory totals")
      ChipTransaction.should_receive(:get_chip_totals).with(@chip_transactions).
        and_return(@totals)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index, :chip_type_id => 23, :lab_group_id => 42
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render the found chip_transactions as xml" do
      @chip_transactions.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /chip_transactions/1.xml" do

    before(:each) do
      @chip_transaction = mock_model(ChipTransaction, :to_xml => "XML")
      ChipTransaction.stub!(:find).and_return(@chip_transaction)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the chip_transaction requested" do
      ChipTransaction.should_receive(:find).with("1").and_return(@chip_transaction)
      do_get
    end
  
    it "should render the found chip_transaction as xml" do
      @chip_transaction.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /chip_transactions/1.json" do

    before(:each) do
      @chip_transaction = mock_model(ChipTransaction, :to_json => "JSON")
      ChipTransaction.stub!(:find).and_return(@chip_transaction)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the chip_transaction requested" do
      ChipTransaction.should_receive(:find).with("1").and_return(@chip_transaction)
      do_get
    end
  
    it "should render the found chip_transaction as json" do
      @chip_transaction.should_receive(:to_json).and_return("JSON")
      do_get
      response.body.should == "JSON"
    end
  end
  
  describe "handling GET /chip_transactions/new" do

    before(:each) do
      @chip_transaction = mock_model(ChipTransaction)
      ChipTransaction.stub!(:new).and_return(@chip_transaction)
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
  
    it "should create an new chip_transaction" do
      ChipTransaction.should_receive(:new).and_return(@chip_transaction)
      do_get
    end
  
    it "should not save the new chip_transaction" do
      @chip_transaction.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new chip_transaction for the view" do
      do_get
      assigns[:chip_transaction].should equal(@chip_transaction)
    end
  end

  describe "handling GET /chip_transactions/1/edit" do

    before(:each) do
      @chip_transaction = mock_model(ChipTransaction)
      ChipTransaction.stub!(:find).and_return(@chip_transaction)
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
  
    it "should find the chip_transaction requested" do
      ChipTransaction.should_receive(:find).and_return(@chip_transaction)
      do_get
    end
  
    it "should assign the found ChipTransaction for the view" do
      do_get
      assigns[:chip_transaction].should equal(@chip_transaction)
    end
  end

  describe "handling POST /chip_transactions" do

    before(:each) do
      @chip_transaction = mock_model(ChipTransaction, :lab_group => mock_model(LabGroup), :chip_type => mock_model(ChipType))
      ChipTransaction.stub!(:new).and_return(@chip_transaction)
    end
    
    describe "with successful save" do
  
      def do_post
        @chip_transaction.should_receive(:save).and_return(true)
        post :create, :chip_transaction => {}
      end
  
      it "should create a new chip_transaction" do
        ChipTransaction.should_receive(:new).with({}).and_return(@chip_transaction)
        do_post
      end

      it "should redirect to the chip_transaction index" do
        do_post
        response.should redirect_to(lab_group_chip_type_chip_transactions_url(@chip_transaction.lab_group, @chip_transaction.chip_type))
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @chip_transaction.should_receive(:save).and_return(false)
        post :create, :chip_transaction => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /chip_transactions/1" do

    before(:each) do
      @chip_transaction = mock_model(ChipTransaction, :lab_group => mock_model(LabGroup), :chip_type => mock_model(ChipType))
      ChipTransaction.stub!(:find).and_return(@chip_transaction)
    end
    
    describe "with successful update" do

      def do_put
        @chip_transaction.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the chip_transaction requested" do
        ChipTransaction.should_receive(:find).with("1").and_return(@chip_transaction)
        do_put
      end

      it "should update the found chip_transaction" do
        do_put
        assigns(:chip_transaction).should equal(@chip_transaction)
      end

      it "should assign the found chip_transaction for the view" do
        do_put
        assigns(:chip_transaction).should equal(@chip_transaction)
      end

      it "should redirect to the chip_transaction index" do
        do_put
        response.should redirect_to(lab_group_chip_type_chip_transactions_url(@chip_transaction.lab_group, @chip_transaction.chip_type))
      end

    end
    
    describe "with failed update" do

      def do_put
        @chip_transaction.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /chip_transactions/1" do

    before(:each) do
      @chip_transaction = mock_model( ChipTransaction, :lab_group => mock_model(LabGroup),
                                      :chip_type => mock_model(ChipType), :destroy => true )
      ChipTransaction.stub!(:find).and_return(@chip_transaction)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the chip_transaction requested" do
      ChipTransaction.should_receive(:find).with("1").and_return(@chip_transaction)
      do_delete
    end
  
    it "should call destroy on the found chip_transaction" do
      @chip_transaction.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the chip_transactions list" do
      do_delete
      response.should redirect_to(lab_group_chip_type_chip_transactions_url(@chip_transaction.lab_group, @chip_transaction.chip_type))
    end
  end
end
