=begin rapidoc
name:: /samples

This resource can be used to list a summary of all samples, or show details for 
a particular sample.<br><br>
=end

class SamplesController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections, :only => :edit
  before_filter :manager_or_investigator_required, :only => :approve
  
=begin rapidoc
url:: /samples
method:: GET
example:: <%= SiteConfig.site_url %>/samples
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Sample.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= Sample.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of all summary information on all samples

Get a list of all samples, which doesn't have all the details that are 
available when retrieving single samples (see GET /samples/[sample id]).
=end
  
  def index
    respond_to do |format|
      format.html do
        @lab_groups = current_user.accessible_lab_groups

        @browse_categories = Sample.browsing_categories
        @grid_action = grid_samples_url
      end
      format.xml   do
        @samples = Sample.accessible_to_user(current_user, params[:age_limit])
        render :xml => @samples.collect{|x| x.summary_hash}
      end
      format.json  do
        @samples = Sample.accessible_to_user(current_user, params[:age_limit])
        render :json => @samples.collect{|x| x.summary_hash}.to_json 
      end
    end
  end

=begin rapidoc
url:: /samples/[sample id]
method:: GET
example:: <%= SiteConfig.site_url %>/samples/100.json
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Sample.find(:first).detail_hash) %>
xml:: <%= Sample.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular sample

Get detailed information about a single sample.
=end
  
  def show
    @sample = Sample.find(
      params[:id],
      :include => {
        :sample_terms => {
          :naming_term => :naming_element
        }
      }
    )

    respond_to do |format|
      format.xml   { render :xml => @sample.detail_hash }
      format.json  { render :json => @sample.detail_hash.to_json }
    end    
  end
  
  def edit
    @sample = Sample.find(params[:id])
     
    @naming_scheme = @sample.microarray.chip.sample_set.naming_scheme
    if(@naming_scheme != nil)
      @naming_elements = @naming_scheme.ordered_naming_elements
    end
    
    # put Sample in an array
    @samples = [@sample]
  end

  def update
    @sample = Sample.find(params[:id])

    respond_to do |format|
      if @sample.update_attributes(params[:sample]["0"])
        flash[:notice] = 'Sample was successfully updated.'
        format.html { redirect_back }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html {
          load_dropdown_selections
          render :action => "edit"
        }
        format.xml  { render :xml => @sample.errors, :status => :unprocessable_entity }
        format.json  { render :json => @sample.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    sample = Sample.find(params[:id])

    if(sample.status == "submitted")
      sample.destroy
    else
      flash[:warning] = "Unable to destroy samples that have already been clustered or sequenced."
    end
    
    respond_to do |format|
      format.html { redirect_to :back }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end
  
  def bulk_handler
    selected_samples = params[:selected_samples]
    
    @samples = Array.new
    for sample_id in selected_samples.keys
      if selected_samples[sample_id] == '1'
        @samples << Sample.find(sample_id)
      end
    end

    if(params[:commit] == "Delete Selected Samples")
      if(current_user.staff_or_admin?)
        flash[:notice] = ""
        flash[:warning] = ""
        @samples.each do |s|
          if(s.submitted?)
            s.destroy
            flash[:notice] += "Sample #{s.short_sample_name} was destroyed<br>"
          else
            flash[:warning] += 
              "Sample #{s.short_sample_name} has already been hybridized, and can't be destroyed<br>"
          end
        end
      else
        flash[:warning] = "Only facility staff can delete multiple samples at a time"
      end

      redirect_to(samples_url)
    elsif(params[:commit] == "Show Details")
      render :action => "details"
    end
  end
  
  def browse
    @samples = Sample.accessible_to_user(current_user)
    categories = sorted_categories(params)

    @tree = Sample.browse_by(@samples, categories)

    respond_to do |format|
      format.html  #browse.html
    end
  end

  def search
    respond_to do |format|
      format.html {
        # create a cache for the samples queried
        sample_list = SampleList.create

        @lab_groups = current_user.accessible_lab_groups
        @browse_categories = Sample.browsing_categories

        @grid_action = request.url + "&sample_list_id=" + sample_list.id.to_s
        render :action => "index"
      }
      format.json {
        # see if this search is cached
        sample_list = SampleList.find(params[:sample_list_id]) if params[:sample_list_id]

        if(sample_list && sample_list.samples.size > 0)
          samples = sample_list.samples          
        else
          accessible_samples = Sample.accessible_to_user(current_user)
          search_samples = Sample.find_by_sanitized_conditions(params)
          samples = accessible_samples & search_samples

          # cache samples queried
          if(sample_list)
            sample_list << samples
          end
        end

        paged_samples = paginate(samples, params[:page].to_i, params[:rows].to_i)

        render :json => paged_samples.to_jqgrid_json(
          ["microarray.chip.sample_set.submission_date", :short_sample_name, :sample_name, "microarray.chip.status",
           "microarray.chip.sample_set.submitted_by", "microarray.chip.sample_set.project.name"], 
          params[:page], params[:rows], samples.size
        )
      }
    end
  end

  def grid
    samples = Sample.find(:all, :include => {:microarray => {:chip => {:sample_set => :project}}}) do
      if params[:_search] == "true"
        microarray.chip.sample_set.submission_date =~ "%#{params["sample_sets.submission_date"]}%" if params["sample_sets.submission_date"].present?                
        short_sample_name                          =~ "%#{params["short_sample_name"]}%" if params["short_sample_name"].present?
        sample_name                                =~ "%#{params[:sample_name]}%" if params[:sample_name].present?                
        microarray.chip.status                     =~ "%#{params[:status]}%" if params[:status].present? 
        microarray.chip.sample_set.submitted_by    =~ "%#{params[:submitted_by]}%" if params[:submitted_by].present?                
        microarray.chip.sample_set.project.name    =~ "%#{params["projects.name"]}%" if params["projects.name"].present?                
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => samples.to_jqgrid_json(
      ["microarray.chip.sample_set.submission_date", :short_sample_name, :sample_name, "microarray.chip.status",
       "microarray.chip.sample_set.submitted_by", "microarray.chip.sample_set.project.name"], 
      params[:page], params[:rows], samples.total_entries
    )
  end

  def approve
    accessible_projects = Project.accessible_to_user(current_user)
    @samples = Sample.find(:all, :conditions => ["project_id IN (?) and status = ?",
                           accessible_projects.collect{|p| p.id}, 'submitted'], :order => "id ASC")
  end

private

  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
    @users = current_user.accessible_users
    @projects = Project.accessible_to_user(current_user)
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")
    @labels = Label.find(:all, :order => "name ASC")
  end

  def sorted_categories(params)
    categories = Array.new

    params.keys.sort.each do |key|
      categories << params[key] if key.match(/category_\d+/)
    end

    return categories
  end

  def paginate(samples, page, rows_per_page)
    pages = samples.size / rows_per_page.to_i
    start_index = (page - 1) * rows_per_page
    end_index = page * rows_per_page

    return samples[start_index..end_index]
  end
end
