class SampleSetsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections
  
  def new
  end

  def create
    sample_set_params = params[:sample_set] || {}
    @sample_set = SampleSet.parse_api( sample_set_params.merge("submitted_by" => current_user.login) )

    if @sample_set.save
      render :json => {:message => "Samples recorded"}
    else
      error_text = @sample_set.error_message
      render :json => {:message => error_text}, :status => :unprocessable_entity
    end
  end

  def edit
    @sample_set = SampleSet.find(params[:id])
    @available_samples = @sample_set.available_samples
  end

  def update
    @sample_set = SampleSet.find(params[:id])
    
    begin
      respond_to do |format|
        if @sample_set.update_attributes(params[:sample_set])
          flash[:notice] = 'Sample set was successfully updated.'
          format.html { redirect_to(root_url) }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @sample_set.errors, :status => :unprocessable_entity }
          format.json  { render :json => @sample_set.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this sample set."
      @sample_set = SampleSet.find(params[:id])
      render :action => 'edit'
    end
  end

  def cancel_new_project
    render :partial => 'projects'
  end
  
  def sample_fields
    @naming_scheme = NamingScheme.find(params[:sample_set][:naming_scheme_id]) if params[:sample_set][:naming_scheme_id]
    @naming_elements = @naming_scheme.naming_elements.find(:all, :order => "element_order ASC") if @naming_scheme
    @number_of_samples = params[:sample_set][:number_of_samples].to_i
    @already_hybridized = params[:sample_set][:already_hybridized] == "true"
    @project = Project.find(params[:sample_set][:project_id])
    @service_option = ServiceOption.find(params[:sample_set][:service_option_id])
    @chip_type = ChipType.find(params[:sample_set][:chip_type_id])
    
    @layout = @chip_type.sample_layout(
      @number_of_samples,
      @service_option.channels
    )

    render :partial => 'sample_fields'
  end

private

  def load_dropdown_selections
    @projects = Project.accessible_to_user(current_user, true)
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :include => :platform, :order => "platforms.name ASC, chip_types.name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")
    @labels = Label.find(:all, :order => "name ASC")
    @service_options = []
  end

end
