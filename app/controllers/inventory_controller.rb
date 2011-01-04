class InventoryController < ApplicationController
  before_filter :login_required

  def index
    accessible_transactions = ChipTransaction.accessible_to_user(current_user)
    @inventories = ChipTransaction.counts_by_lab_group_and_chip_type(accessible_transactions)
  end

end
