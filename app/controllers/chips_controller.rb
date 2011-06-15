class ChipsController < ApplicationController
  before_filter :login_required

  # GET /chips
  def index
  end

  def grid
    chips = Chip.find(:all, :include => {:microarrays => {:samples => :project}}) do
      if params[:_search] == "true"
        hybridization_date      =~ "%#{params[:hybridization_date]}%" if params[:hybridization_date].present?
        name                    =~ "%#{params["name"]}%" if params["name"].present?  
        status                  =~ "%#{params[:status]}%" if params[:status].present? 
        sample_set.submitted_by =~ "%#{params["sample_sets.submitted_by"]}%" if params["sample_sets.submitted_by"].present?                
        project.name            =~ "%#{params["projects.name"]}%" if params["projects.name"].present?                
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => chips.to_jqgrid_json(
      [:hybridization_date, :name, :status, "sample_set.submitted_by",
       "microarrays.first.samples.first.project.name"], 
      params[:page], params[:rows], chips.total_entries
    )
  end

  # GET /chips/1/edit
  def edit
    sample_set = Chip.find(params[:id]).sample_set

    redirect_to edit_sample_set_url(sample_set)
  end

  # PUT /chips/1
  # PUT /chips/1.xml
  def update
    @chip = Chip.find(params[:id])
    @available_samples = @chip.available_samples
    
    begin
      respond_to do |format|
        if @chip.update_attributes(params[:chip])
          @layout = @chip.layout

          flash[:notice] = 'Chip was successfully updated.'
          format.html { render :action => "edit" }
          format.xml  { head :ok }
          format.json  { head :ok }
        else
          @layout = @chip.layout

          format.html { render :action => "edit" }
          format.xml  { render :xml => @chip.errors, :status => :unprocessable_entity }
          format.json  { render :json => @chip.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this chip."
      @chip = Chip.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    Chip.find(params[:id]).destroy
    
    respond_to do |format|
      format.html do
        begin
          redirect_to :back
        rescue
          redirect_to root_url
        end
      end
    end
  end
end
