require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChipIntergroupPurchasesController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff

    LabGroup.should_receive(:find).with(:all, :order => "name ASC").and_return(mock("Lab groups"))
    ChipType.should_receive(:find).with(:all, :order => "name ASC").and_return( mock("Chip types"))

    @lab_group = mock_model(LabGroup, :id => 42)
    @chip_type = mock_model(ChipType, :id => 23)

    @mock_chip_intergroup_purchase = mock("Chip purchase", :lab_group_id => 42, :chip_type_id => 23)
  end

  describe "responding to GET new" do

    before(:each) do
      ChipIntergroupPurchase.should_receive(:new).
        with(:lab_group_id => "42",:chip_type_id => "23").
        and_return(@mock_chip_intergroup_purchase)
    end

    def do_get
      get :new, :lab_group_id => 42, :chip_type_id => 23
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render the 'new' template" do
      do_get
      response.should render_template('new')
    end

  end

  describe "responding to POST create" do

    before(:each) do
      ChipIntergroupPurchase.should_receive(:new).with("params").and_return(@mock_chip_intergroup_purchase)
    end

    def do_post
      post :create, :lab_group_id => 42, :chip_type_id => 23, :chip_intergroup_purchase => "params"
    end

    context "with a successful save" do

      before(:each) do
        @mock_chip_intergroup_purchase.should_receive(:valid?).and_return(true)
        @mock_chip_intergroup_purchase.should_receive(:save).and_return(true)

        LabGroup.should_receive(:find).with(42).and_return(@lab_group)
        ChipType.should_receive(:find).with(23).and_return(@chip_type)
      end

      it "should redirect to the chip transactions" do
        do_post
        response.should redirect_to lab_group_chip_type_chip_transactions_url(@lab_group,@chip_type)
      end

    end

    context "with a failed save" do

      before(:each) do
        @mock_chip_intergroup_purchase.should_receive(:valid?).and_return(false)
      end

      it "should redirect to the chip transactions" do
        do_post
        response.should render_template('new')
      end

    end
  end
end
