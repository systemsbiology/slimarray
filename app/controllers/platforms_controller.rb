class PlatformsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :load_dropdown_selections, :except => [:index, :destroy]
  
  # GET /platforms
  # GET /platforms.xml
  def index
    @platforms = Platform.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @platforms }
    end
  end

  # GET /platforms/1
  # GET /platforms/1.xml
  def show
    @platform = Platform.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @platform }
    end
  end

  # GET /platforms/new
  # GET /platforms/new.xml
  def new
    @platform = Platform.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @platform }
    end
  end

  # GET /platforms/1/edit
  def edit
    @platform = Platform.find(params[:id])
  end

  # POST /platforms
  # POST /platforms.xml
  def create
    @platform = Platform.new(params[:platform])

    respond_to do |format|
      if @platform.save
        flash[:notice] = 'Platform was successfully created.'
        format.html { redirect_to(platforms_url) }
        format.xml  { render :xml => @platform, :status => :created, :location => @platform }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @platform.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /platforms/1
  # PUT /platforms/1.xml
  def update
    @platform = Platform.find(params[:id])

    respond_to do |format|
      if @platform.update_attributes(params[:platform])
        flash[:notice] = 'Platform was successfully updated.'
        format.html { redirect_to(platforms_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @platform.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /platforms/1
  # DELETE /platforms/1.xml
  def destroy
    @platform = Platform.find(params[:id])
    @platform.destroy

    respond_to do |format|
      format.html { redirect_to(platforms_url) }
      format.xml  { head :ok }
    end
  end

  def grid
    platforms = Platform.find(:all) do
      if params[:_search] == "true"
        name                  =~ "%#{params[:name]}%" if params[:name].present?
        has_multi_array_chips =~ "%#{params[:has_multi_array_chips]}%" if params[:has_multi_array_chips].present?
        uses_chip_numbers     =~ "%#{params[:uses_chip_numbers]}%" if params[:uses_chip_numbers].present?
        multiple_labels       =~ "%#{params[:multiple_labels]}%" if params[:multiple_labels].present?
        default_label.name     =~ "%#{params["default_label.name"]}%" if params["default_label.name"].present?
        raw_data_type         =~ "%#{params[:raw_data_type]}%" if params[:raw_data_type].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => platforms.to_jqgrid_json(
      [:name, :has_multi_array_chips, :uses_chip_numbers, :multiple_labels, 'default_label.name',
       :raw_data_type], 
      params[:page], params[:rows], platforms.total_entries
    )
  end

  private

  def load_dropdown_selections
    @labels = Label.find(:all, :order => "name ASC")
  end
end
