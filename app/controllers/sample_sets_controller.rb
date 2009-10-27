class SampleSetsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections
  
  def new
    if(params[:step] == "2")
      @sample_set = SampleSet.new(params[:sample_set])

      if(@sample_set.valid?)
        @naming_scheme = @sample_set.naming_scheme
        if(@naming_scheme != nil)
          @naming_elements = @naming_scheme.ordered_naming_elements
        end

        @samples = Array.new
        params[:sample_set][:number_of_samples].to_i.times do
          sample = Sample.new(
            :submission_date => @sample_set.submission_date,
            :project_id => @sample_set.project_id,
            :naming_scheme_id => @sample_set.naming_scheme_id,
            :organism_id => @sample_set.chip_type.organism_id,
            :chip_type_id => @sample_set.chip_type_id,
            :sbeams_user => @sample_set.sbeams_user,
            :sample_set => @sample_set
          )

          @samples << sample
        end        
      else
        # if the sample set info is invalid, kick back to step 1
        params[:step] = "1"
      end
    else
      @sample_set = SampleSet.new
    end
  end

  def create
    @sample_set = SampleSet.new(params[:sample_set])

    @samples = Array.new
    params[:sample].each_value { |sample| @samples << Sample.new(sample) }
    @sample_set.samples = @samples

    if @sample_set.valid?
      @samples.each do |s|
        s.save
      end
      
      # send notification email
      Notifier.deliver_sample_submission_notification(@samples)
      
      flash[:notice] = 'Samples were successfully created.'
      redirect_to(root_url)
    else
      @naming_scheme = @sample_set.naming_scheme
      if(@naming_scheme != nil)
        @naming_elements = @naming_scheme.ordered_naming_elements
      end
      params[:step] = '2'
      render :action => 'new'
    end
  end

  def cancel_new_project
    render :partial => 'projects'
  end
  
private

  def load_dropdown_selections
    @projects = Project.accessible_to_user(current_user, true)
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")
  end
end
