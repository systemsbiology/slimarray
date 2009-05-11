class ChipPurchasesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :get_lab_group_and_chip_type
  before_filter :populate_lab_group_and_chip_type_choices

  def new
    @chip_purchase = ChipPurchase.new(
      :lab_group_id => @lab_group.id,
      :chip_type_id => @chip_type.id
    )

    respond_to do |format|
      format.html
    end
  end

  def create
    @chip_purchase = ChipPurchase.new(params[:chip_purchase])

    respond_to do |format|
      # have to run valid? here to generate errors on Validatable attributes
      if @chip_purchase.valid? && @chip_purchase.save
        flash[:notice] = 'Chip purchase was successfully created.'
        format.html { redirect_to lab_group_chip_type_chip_transactions_url(@lab_group,@chip_type) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  private

  def get_lab_group_and_chip_type
    @lab_group = LabGroup.find(params[:lab_group_id])
    @chip_type = ChipType.find(params[:chip_type_id])
  end

  def populate_lab_group_and_chip_type_choices
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end
end
