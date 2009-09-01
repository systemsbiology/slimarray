class OrganismsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  
  # GET /organisms
  # GET /organisms.xml
  def index
    @organisms = Organism.find(:all, :order => "name ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @organisms }
      format.json { render :json => @organisms }
    end
  end

  # GET /organisms/1
  # GET /organisms/1.xml
  def show
    @organism = Organism.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @organism }
      format.json  { render :json => @organism }
    end
  end

  # GET /organisms/new
  # GET /organisms/new.xml
  def new
    @organism = Organism.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organism }
      format.json  { render :json => @organism }
    end
  end

  # POST /organisms
  # POST /organisms.xml
  def create
    @organism = Organism.new(params[:organism])
    
    respond_to do |format|
      if @organism.save
        flash[:notice] = 'Organism was successfully created.'
        format.html { redirect_to(organisms_url) }
        format.xml  { render :xml => @organism, :status => :created, :location => @organism }
        format.json  { render :json => @organism, :status => :created, :location => @organism }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
        format.json  { render :json => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /organisms/1/edit
  def edit
    @organism = Organism.find(params[:id])
  end

  # PUT /organisms/1
  # PUT /organisms/1.xml
  def update
    @organism = Organism.find(params[:id])
    
    begin
      respond_to do |format|
        if @organism.update_attributes(params[:organism])
          flash[:notice] = 'Organism was successfully updated.'
          format.html { redirect_to(organisms_url) }
          format.xml  { head :ok }
          format.json  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
          format.json  { render :json => @organism.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this organism."
      @organism = Organism.find(params[:id])
      render :action => 'edit'
    end
  end

  # DELETE /organisms/1
  # DELETE /organisms/1.xml
  def destroy
    Organism.find(params[:id]).destroy
    
    respond_to do |format|
      format.html { redirect_to(organisms_url) }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end

  def grid
    organisms = Organism.find(:all) do
      if params[:_search] == "true"
        name      =~ "%#{params[:name]}%" if params[:name].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => organisms.to_jqgrid_json(
      [:name], 
      params[:page], params[:rows], organisms.total_entries
    )
  end

end
