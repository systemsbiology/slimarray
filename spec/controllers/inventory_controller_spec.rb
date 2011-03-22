require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InventoryController do
  include AuthenticatedSpecHelper

  describe "handling GET /inventory" do
    before(:each) do
      login_as_user

      @transactions = mock("Transactions")
      @inventories = mock("Inventories")
      ChipTransaction.stub!(:accessible_to_user).and_return(@transactions)
      ChipTransaction.stub!(:counts_by_lab_group_and_chip_type).and_return(@inventories)
    end
  
    def do_get
      get :index
    end

    it "finds the transactions accessible to the current user" do
      ChipTransaction.should_receive(:accessible_to_user).with(@current_user).and_return(@transactions)
      do_get
    end

    it "gets the counts for the accessible transactions" do
      ChipTransaction.should_receive(:counts_by_lab_group_and_chip_type).and_return(@inventories)
      do_get
    end
  end
end
