class ChargesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :get_charge_set

  def index
    @charges = @charge_set.charges.find(:all, :order => 'date ASC, description ASC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @charges }
      format.json { render :json => @charges }
    end
  end

  # GET /charges/1
  # GET /charges/1.xml
  def show
    @charge = @charge_set.charges.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @charge }
      format.json  { render :json => @charge }
    end
  end

  def new
    @charge = Charge.from_template_id( params[:charge_template_id], @charge_set )
                               
    @charge_templates = ChargeTemplate.find(:all, :order => "name ASC")

    respond_to do |format|
      format.html { render :action => 'new' }
      format.xml  { render :xml => @charge }
      format.json { render :json => @charge }
    end
  end

  def new_from_template
    new  
  end

  def create
    @charge = @charge_set.charges.new(params[:charge])

    respond_to do |format|
      if @charge.save
        flash[:notice] = 'Charge was successfully created.'
        format.html { redirect_to( charge_set_charges_url(@charge_set) ) }
        format.xml  { render :xml => @charge, :status => :created, :location => @charge }
        format.json  { render :json => @charge, :status => :created, :location => @charge }
      else
        @charge_templates = ChargeTemplate.find(:all, :order => "name ASC")
        
        format.html { render :action => "new" }
        format.xml  { render :xml => @charge.errors, :status => :unprocessable_entity }
        format.json  { render :json => @charge.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @charge = @charge_set.charges.find(params[:id])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @charge }
      format.json  { render :json => @charge }
    end
  end

  def update
    @charge = @charge_set.charges.find(params[:id])

    begin
      respond_to do |format|
        if @charge.update_attributes(params[:charge])
          flash[:notice] = 'Charge was successfully updated.'
          format.html { redirect_to( charge_set_charges_url(@charge_set) ) }
          format.xml  { head :ok }
          format.json  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @charge.errors, :status => :unprocessable_entity }
          format.json  { render :json => @charge.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this charge."
      @charge = Charge.find(params[:id])
      render :action => 'edit'
    end
  end

  def bulk_edit_move_or_destroy
    # edit, move or destroy?
    if(params[:commit] == "Set Field")
      name = params[:field_name]
      value = params[:field_value]
      selected_charges = params[:selected_charges]
      success = true
      for charge_id in selected_charges.keys
        if selected_charges[charge_id] == '1'
          charge = Charge.find(charge_id)
          # update charge and keep track of whether any updates fail
          if( !charge.update_attributes( name => value ) )
            success = false
          end
        end
      end

      if( !success )
        flash[:warning] = "Setting field failed for one or more charges"
      end
    elsif(params[:commit] == "Move Charges To This Charge Set")
      charge_set_id = params[:move_charge_set_id]
      selected_charges = params[:selected_charges]
      for charge_id in selected_charges.keys
        if selected_charges[charge_id] == '1'
          charge = Charge.find(charge_id)
          charge.update_attributes( { :charge_set_id => charge_set_id } )
        end
      end
      
      # change current charge set to the one where we moved the charges
      session[:charge_set] = ChargeSet.find(charge_set_id.to_i)
    elsif(params[:commit] == "Delete Charges")
      selected_charges = params[:selected_charges]
      for charge_id in selected_charges.keys
        if selected_charges[charge_id] == '1'
          charge = Charge.find(charge_id)
          charge.destroy
        end
      end
    end
    
    redirect_to charge_set_charges_url(@charge_set)
  end

  def select_from_sbeams
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
  end

  def import_from_sbeams
    username = params[:username]
    password = params[:password]
    request_id = params[:request_id]
    lab_group_id = params[:lab_group_id]

    begin
      Charge.scrape_array_request(username, password, request_id, lab_group_id)
      flash[:notice] = "Import complete"
      redirect_to :controller => 'charge_sets', :action => 'list'
    rescue
      flash[:warning] = "Unable to import array request. Check SBEAMS " +
        "address in site configuration, and ensure that the array request " +
        "has been set to 'finished'."
      select_from_sbeams
      render 'charges/select_from_sbeams'
    end

  end

  def destroy
    @charge_set.charges.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to( charge_set_charges_url(@charge_set) ) }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end

  private

  def get_charge_set
    @charge_set = ChargeSet.find(params[:charge_set_id]) if params[:charge_set_id]
  end
end
