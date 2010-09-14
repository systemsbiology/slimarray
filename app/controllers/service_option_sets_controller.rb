class ServiceOptionSetsController < ApplicationController
  before_filter :load_service_options, :except => [:index, :destroy]

  # GET /service_option_sets
  # GET /service_option_sets.xml
  def index
    @service_option_sets = ServiceOptionSet.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @service_option_sets }
    end
  end

  # GET /service_option_sets/1
  # GET /service_option_sets/1.xml
  def show
    @service_option_set = ServiceOptionSet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_option_set }
    end
  end

  # GET /service_option_sets/new
  # GET /service_option_sets/new.xml
  def new
    @service_option_set = ServiceOptionSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @service_option_set }
    end
  end

  # GET /service_option_sets/1/edit
  def edit
    @service_option_set = ServiceOptionSet.find(params[:id])
  end

  # POST /service_option_sets
  # POST /service_option_sets.xml
  def create
    @service_option_set = ServiceOptionSet.new(params[:service_option_set])

    respond_to do |format|
      if @service_option_set.save
        flash[:notice] = 'ServiceOptionSet was successfully created.'
        format.html { redirect_to(service_option_sets_url) }
        format.xml  { render :xml => @service_option_set, :status => :created, :location => @service_option_set }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @service_option_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /service_option_sets/1
  # PUT /service_option_sets/1.xml
  def update
    @service_option_set = ServiceOptionSet.find(params[:id])

    respond_to do |format|
      if @service_option_set.update_attributes(params[:service_option_set])
        flash[:notice] = 'ServiceOptionSet was successfully updated.'
        format.html { redirect_to(service_option_sets_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service_option_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /service_option_sets/1
  # DELETE /service_option_sets/1.xml
  def destroy
    @service_option_set = ServiceOptionSet.find(params[:id])
    @service_option_set.destroy

    respond_to do |format|
      format.html { redirect_to(service_option_sets_url) }
      format.xml  { head :ok }
    end
  end

  private

  def load_service_options
    @service_options = ServiceOption.find(:all, :order => "name ASC")
  end
end
