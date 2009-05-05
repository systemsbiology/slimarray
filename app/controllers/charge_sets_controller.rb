class ChargeSetsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  # GET /charge_sets
  # GET /charge_sets.xml
  # GET /charge_sets.json
  def index
    @charge_periods = ChargePeriod.find(:all, :order => "name DESC",
                                        :limit => 4)
    @charge_sets = ChargeSet.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @charge_sets }
      format.json { render :json => @charge_sets }
    end
  end

  def list_all
    @charge_periods = ChargePeriod.find(:all, :order => "name DESC")
    @charge_sets = ChargeSet.find(:all)

    respond_to do |format|
      format.html { render :action => 'index' }
      format.xml  { render :xml => @charge_sets }
      format.json { render :json => @charge_sets }
    end
  end

  # GET /charge_sets/1
  # GET /charge_sets/1.xml
  def show
    @charge_set = ChargeSet.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @charge_set }
      format.json  { render :json => @charge_set }
    end
  end

  def new
    @charge_set = ChargeSet.new
    populate_for_dropdown

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @charge_set }
      format.json  { render :json => @charge_set }
    end
  end

  def create
    @charge_set = ChargeSet.new(params[:charge_set])
    populate_for_dropdown
    
    respond_to do |format|
      if @charge_set.save
        flash[:notice] = 'ChargeSet was successfully created.'
        format.html { redirect_to(charge_sets_url) }
        format.xml  { render :xml => @charge_set, :status => :created, :location => @charge_set }
        format.json  { render :json => @charge_set, :status => :created, :location => @charge_set }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @charge_set.errors, :status => :unprocessable_entity }
        format.json  { render :json => @charge_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @charge_set = ChargeSet.find(params[:id])
    populate_for_dropdown
  end

  def update
    @charge_set = ChargeSet.find(params[:id])
    populate_for_dropdown

    begin
      respond_to do |format|
        if @charge_set.update_attributes(params[:charge_set])
          flash[:notice] = 'ChargeSet was successfully updated.'
          format.html { redirect_to(charge_sets_url) }
          format.xml  { head :ok }
          format.json  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @charge_set.errors, :status => :unprocessable_entity }
          format.json  { render :json => @charge_set.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this charge set."
      @charge_set = ChargeSet.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    begin
      ChargeSet.find(params[:id]).destroy

      respond_to do |format|
        format.html { redirect_to(charge_sets_url) }
        format.xml  { head :ok }
        format.json  { head :ok }
      end
    rescue
      flash[:warning] = "Cannot delete charge set due to association " +
                        "with one or more charges."
      redirect_to charge_sets_url
    end
  end
  
  private
  def populate_for_dropdown
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @charge_periods = ChargePeriod.find(:all, :order => "name DESC")
  end
end
