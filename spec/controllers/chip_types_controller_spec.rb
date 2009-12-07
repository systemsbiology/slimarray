require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChipTypesController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff
  end
  
  describe "handling GET /chip_types" do

    before(:each) do
      @chip_type = mock_model(ChipType)
      ChipType.stub!(:find).and_return([@chip_type])
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
  
    it "should find all chip_types" do
      ChipType.should_receive(:find).
        with(:all, :order => "name ASC", :include => :organism).
        and_return([@chip_type])
      do_get
    end
  
    it "should assign the found chip_types for the view" do
      do_get
      assigns[:chip_types].should == [@chip_type]
    end
  end

  describe "handling GET /chip_types.xml" do

    before(:each) do
      @chip_type_1 = mock_model(ChipType, :summary_hash => {:n => 1})
      @chip_type_2 = mock_model(ChipType, :summary_hash => {:n => 2})
      @chip_types = [@chip_type_1, @chip_type_2]
      ChipType.stub!(:find).and_return(@chip_types)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all chip_types" do
      ChipType.should_receive(:find).
        with(:all, :order => "name ASC", :include => :organism).
        and_return(@chip_types)
      do_get
    end
  
    it "should render the found chip_types as xml" do
      do_get
      response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
        "<records type=\"array\">\n  <record>\n    <n type=\"integer\">1</n>\n  </record>\n  " +
        "<record>\n    <n type=\"integer\">2</n>\n  </record>\n</records>\n"
    end
  end

  describe "handling GET /chip_types/1.xml" do

    before(:each) do
      @chip_type = mock_model(ChipType, :detail_hash => {:n => 1})
      ChipType.stub!(:find).and_return(@chip_type)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the chip_type requested" do
      ChipType.should_receive(:find).with("1").and_return(@chip_type)
      do_get
    end
  
    it "should render the found chip_type as xml" do
      @chip_type.should_receive(:detail_hash).and_return({:n => 1})
      do_get
      response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  " +
        "<n type=\"integer\">1</n>\n</hash>\n"
    end
  end

  describe "handling GET /chip_types/1.json" do

    before(:each) do
      @chip_type = mock_model(ChipType, :detail_hash => {:n => 1})
      ChipType.stub!(:find).and_return(@chip_type)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the chip_type requested" do
      ChipType.should_receive(:find).with("1").and_return(@chip_type)
      do_get
    end
  
    it "should render the found chip_type as json" do
      @chip_type.should_receive(:detail_hash).and_return({:n => 1})
      do_get
      response.body.should =~ /\{\"n\":\s*1\}/
    end
  end
  
  describe "handling GET /chip_types/new" do

    before(:each) do
      @chip_type = mock_model(ChipType)
      ChipType.stub!(:new).and_return(@chip_type)
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
  
    it "should create an new chip_type" do
      ChipType.should_receive(:new).and_return(@chip_type)
      do_get
    end
  
    it "should not save the new chip_type" do
      @chip_type.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new chip_type for the view" do
      do_get
      assigns[:chip_type].should equal(@chip_type)
    end
  end

  describe "handling GET /chip_types/1/edit" do

    before(:each) do
      @chip_type = mock_model(ChipType)
      ChipType.stub!(:find).and_return(@chip_type)
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
  
    it "should find the chip_type requested" do
      ChipType.should_receive(:find).and_return(@chip_type)
      do_get
    end
  
    it "should assign the found ChipType for the view" do
      do_get
      assigns[:chip_type].should equal(@chip_type)
    end
  end

  describe "handling POST /chip_types" do

    describe "with an existing organism and successful save" do

      before(:each) do
        @chip_type = mock_model(ChipType, :organism_id => 21)
        ChipType.stub!(:new).and_return(@chip_type)
      end
  
      def do_post
        @chip_type.should_receive(:save).and_return(true)
        post :create, :chip_type => {:organism_id => 21}
      end
  
      it "should create a new chip_type" do
        ChipType.should_receive(:new).with({"organism_id" => 21}).and_return(@chip_type)
        do_post
      end

      it "should redirect to the chip_type index" do
        do_post
        response.should redirect_to(chip_types_url)
      end
      
    end
    
    describe "with a new organism and successful save" do
  
      before(:each) do
        @chip_type = mock_model(ChipType, :organism_id => -1)
        ChipType.should_receive(:new).and_return(@chip_type)
        @organism = mock_model(Organism)
        Organism.stub!(:new).and_return(@organism)
        @organism.should_receive(:save).and_return(true)
        @chip_type.should_receive(:update_attribute).with('organism_id',@organism.id)
      end

      def do_post
        @chip_type.should_receive(:save).and_return(true)
        post :create, :chip_type => {:organism_id => -1}, :organism => "Liger"
      end
  
      it "should create a new organism" do
        Organism.should_receive(:new).and_return(@organism)
        do_post
      end

      it "should redirect to the chip_type index" do
        do_post
        response.should redirect_to(chip_types_url)
      end
      
    end

    describe "with an existing organism and a failed save" do

      before(:each) do
        @chip_type = mock_model(ChipType, :organism_id => 21)
        ChipType.stub!(:new).and_return(@chip_type)
      end
  
      def do_post
        @chip_type.should_receive(:save).and_return(false)
        post :create, :chip_type => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /chip_types/1" do

    before(:each) do
      @chip_type = mock_model(ChipType, :to_param => "1")
      ChipType.stub!(:find).and_return(@chip_type)
    end
    
    describe "with successful update" do

      def do_put
        @chip_type.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the chip_type requested" do
        ChipType.should_receive(:find).with("1").and_return(@chip_type)
        do_put
      end

      it "should update the found chip_type" do
        do_put
        assigns(:chip_type).should equal(@chip_type)
      end

      it "should assign the found chip_type for the view" do
        do_put
        assigns(:chip_type).should equal(@chip_type)
      end

      it "should redirect to the chip_type index" do
        do_put
        response.should redirect_to(chip_types_url)
      end

    end
    
    describe "with failed update" do

      def do_put
        @chip_type.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /chip_types/1" do

    before(:each) do
      @chip_type = mock_model(ChipType, :destroy => true)
      ChipType.stub!(:find).and_return(@chip_type)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the chip_type requested" do
      ChipType.should_receive(:find).with("1").and_return(@chip_type)
      do_delete
    end
  
    it "should call destroy on the found chip_type" do
      @chip_type.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the chip_types list" do
      do_delete
      response.should redirect_to(chip_types_url)
    end
  end
end
