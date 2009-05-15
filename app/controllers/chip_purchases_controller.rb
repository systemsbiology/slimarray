class ChipPurchasesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :populate_lab_group_and_chip_type_choices

  def new
    @chip_purchase = ChipPurchase.new(
      :lab_group_id => params[:lab_group_id],
      :chip_type_id => params[:chip_type_id]
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
        lab_group = LabGroup.find(@chip_purchase.lab_group_id)
        chip_type = ChipType.find(@chip_purchase.chip_type_id)

        flash[:notice] = 'Chip purchase was successfully created.'
        format.html { redirect_to lab_group_chip_type_chip_transactions_url(lab_group,chip_type) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  private

  def populate_lab_group_and_chip_type_choices
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end
end
