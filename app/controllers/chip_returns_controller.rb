class ChipReturnsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :populate_lab_group_and_chip_type_choices

  def new
    @chip_return = ChipReturn.new(
      :from_lab_group_id => params[:lab_group_id],
      :chip_type_id => params[:chip_type_id]
    )

    respond_to do |format|
      format.html
    end
  end

  def create
    @chip_return = ChipReturn.new(params[:chip_return])

    respond_to do |format|
      # have to run valid? here to generate errors on Validatable attributes
      if @chip_return.valid? && @chip_return.save
        lab_group = LabGroup.find(@chip_return.from_lab_group_id)
        chip_type = ChipType.find(@chip_return.chip_type_id)

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
