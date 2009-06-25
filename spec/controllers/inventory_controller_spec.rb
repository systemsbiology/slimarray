require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InventoryController do
  include AuthenticatedSpecHelper

  describe "handling GET /inventory" do

    before(:each) do
      @lab_groups = mock("Lab groups")
      @chip_types = mock("Chip types")
      ChipType.should_receive(:find).with(:all, :order => "name ASC").and_return(@chip_types)
    end
  
    def do_get
      get :index
    end
  
    describe "as a staff or admin user" do

      before(:each) do
        login_as_staff
        LabGroup.stub!(:find).and_return(@lab_groups)
      end

      it "should be successful" do
        do_get
        response.should be_success
      end

      it "should render index template" do
        do_get
        response.should render_template('index')
      end
    
      it "should find all lab groups" do
        LabGroup.should_receive(:find).with(:all, :order => "name ASC").and_return(@lab_groups)
        do_get
      end
    
      it "should assign the chip types and lab groups for the view" do
        do_get
        assigns[:chip_types].should == @chip_types
        assigns[:lab_groups].should == @lab_groups
      end

    end

    describe "as a customer user" do

      before(:each) do
        login_as_user
        @current_user.stub!(:lab_groups).and_return(@lab_groups)
      end

      it "should be successful" do
        do_get
        response.should be_success
      end

      it "should render index template" do
        do_get
        response.should render_template('index')
      end
    
      it "should find the lab groups this user has access to" do
        @current_user.should_receive(:lab_groups).and_return(@lab_groups)
        do_get
      end
    
      it "should assign the chip types and lab groups for the view" do
        do_get
        assigns[:chip_types].should == @chip_types
        assigns[:lab_groups].should == @lab_groups
      end

    end

  end

end
