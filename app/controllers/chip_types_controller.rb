class ChipTypesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :load_dropdown_selections, :except => [:index, :destroy]
  
   def index
    @chip_types = ChipType.find(
      :all,
      :order => "name ASC",
      :include => :organism
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
      redirect_to chip_types_url
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
        array_platform  =~ "%#{params[:array_platform]}%" if params[:array_platform].present?
        library_package =~ "%#{params[:array_platform]}%" if params[:array_platform].present?        
        organism.name   =~ "%#{params["organisms.name"]}%" if params["organisms.name"].present?        
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => chip_types.to_jqgrid_json(
      ["name",:short_name,:array_platform,:library_package,"organism.name"], 
      params[:page], params[:rows], ChipType.count
    )
  end

  private

  def load_dropdown_selections
    @organisms = Organism.find(:all, :order => "name ASC")
  end
end
