class InventoryChecksController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def index
    # just render jqGrid, which loads data from the 'grid' action
  end

  def new
    populate_arrays_from_tables
    
    @inventory_check = InventoryCheck.new
    if(params[:expected] != nil)
      @inventory_check.number_expected = params[:expected]
    end
    if(params[:lab_group_id] != nil)
      @inventory_check.lab_group_id = params[:lab_group_id]
    end
    if(params[:chip_type_id] != nil)
      @inventory_check.chip_type_id = params[:chip_type_id]
    end    
  end

  def create
    populate_arrays_from_tables
  
    @inventory_check = InventoryCheck.new(params[:inventory_check])
    if @inventory_check.save
      flash[:notice] = 'InventoryCheck was successfully created.'
      redirect_to :controller => 'inventory', :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    populate_arrays_from_tables
  
    @inventory_check = InventoryCheck.find(params[:id])
  end

  def update
    populate_arrays_from_tables
    
    @inventory_check = InventoryCheck.find(params[:id])
    begin
      if @inventory_check.update_attributes(params[:inventory_check])
        flash[:notice] = 'InventoryCheck was successfully updated.'
        redirect_to inventory_checks_url 
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this inventory check."
      @inventory_check = InventoryCheck.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    InventoryCheck.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to inventory_checks_url }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end
  
  def grid
    inventory_checks = InventoryCheck.find(:all, :include => [:chip_type]) do
      if params[:_search] == "true"
        inventory_check.date =~ "%#{params["inventory_checks.date"]}%" if params["inventory_checks.date"].present?
        lab_group.name       =~ "%#{params["lab_groups.name"]}%" if params["lab_groups.name"].present?                
        chip_type.name       =~ "%#{params["chip_types.name"]}%" if params["chip_types.name"].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => inventory_checks.to_jqgrid_json(
      [:date, "lab_group_name", "chip_type.name", :number_expected, :number_counted], 
      params[:page], params[:rows], inventory_checks.total_entries
    )
  end

  private
  def populate_arrays_from_tables
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")    
  end
end
