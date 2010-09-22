=begin rapidoc
name:: /chip_types

This resource can be used to list a summary of all chip types, or show details for 
a particular chip type.<br><br>
=end

class ChipTypesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required, :except => :service_options
  before_filter :load_dropdown_selections, :except => [:index, :destroy]
  
=begin rapidoc
url:: /chip_types
method:: GET
example:: <%= SiteConfig.site_url %>/chip_types
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(ChipType.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= ChipType.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of all summary information on all chip types

Get a list of all chip types, which doesn't have all the details that are 
available when retrieving single chip types (see GET /chip_types/[chip type id]).
=end
  
   def index
    @chip_types = ChipType.find(
      :all,
      :order => "name ASC",
      :include => [:organism, :platform]
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @chip_types.
        collect{|x| x.summary_hash}
      }
      format.json { render :json => @chip_types.
        collect{|x| x.summary_hash}
      }
    end
  end
  
=begin rapidoc
url:: /chip_types/[chip type id]
method:: GET
example:: <%= SiteConfig.site_url %>/chip_types/5.json
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(ChipType.find(:first).detail_hash) %>
xml:: <%= ChipType.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular chip type

Get detailed information about a single chip type.
=end

  def show
    @chip_type = ChipType.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @chip_type.detail_hash }
      format.json  { render :json => @chip_type.detail_hash }
    end
  end

  def new
    @chip_type = ChipType.new
  end

  def create
    @chip_type = ChipType.new(params[:chip_type])
    
    # if a new organism was specified, use that name
    if(@chip_type.organism_id == -1)
      @organism = Organism.new(:name => params[:organism])
      if @organism.save
        @chip_type.update_attribute('organism_id', @organism.id)
      end
    end
    
    # try to save the new chip type
    if(@chip_type.save)
      flash[:notice] = 'ChipType was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @chip_type = ChipType.find(params[:id])
  end

  def update
    @chip_type = ChipType.find(params[:id])
    
    # catch StaleObjectErrors
    begin
      if @chip_type.update_attributes(params[:chip_type])
        # if a new chip_type was specified, use that name
        if(params[:organism] != nil && params[:organism].size > 0)
          @organism = Organism.new(:name => params[:organism])
          @organism.save
          @chip_type.update_attribute('organism_id', @organism.id)
        end
      
        flash[:notice] = 'ChipType was successfully updated.'
        redirect_to :action => 'index'
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this chip type."
      @chip_type = ChipType.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    begin
      ChipType.find(params[:id]).destroy

      respond_to do |format|
        format.html { redirect_to chip_types_url }
        format.xml  { head :ok }
        format.json  { head :ok }
      end
    rescue
      flash[:warning] = "Cannot delete chip type due to association " +
                        "with chip transactions or hybridizations."
      index
      render :action => 'index'
    end
  end
  
  def grid
    chip_types = ChipType.find(:all, :include => :organism) do
      if params[:_search] == "true"
        name =~ "%#{params["chip_types.name"]}%" if params["chip_types.name"].present?
        short_name      =~ "%#{params[:short_name]}%" if params[:short_name].present?                
        platform.name   =~ "%#{params[:platform]}%" if params[:platform].present?
        arrays_per_chip =~ "%#{params[:arrays_per_chip]}%" if params[:arrays_per_chip].present?
        library_package =~ "%#{params[:library_package]}%" if params[:libarary_package].present?
        organism.name   =~ "%#{params["organisms.name"]}%" if params["organisms.name"].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => chip_types.to_jqgrid_json(
      ["name",:short_name,"platform.name",:arrays_per_chip,:library_package,"organism.name"], 
      params[:page], params[:rows], ChipType.count
    )
  end

  def service_options
    @service_options = ChipType.find(params[:id]).service_options.find(:all, :order => "name ASC")

    render :partial => 'service_options'
  end

  private

  def load_dropdown_selections
    @organisms = Organism.find(:all, :order => "name ASC")
    @platforms = Platform.find(:all, :order => "name ASC")
    @service_option_sets = ServiceOptionSet.find(:all, :order => "name ASC")
  end
end
