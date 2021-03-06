=begin rapidoc
name:: /projects

This resource can be used to list a summary of all projects, or show details for 
a particular project.<br><br>

Each project belongs to a particular lab group. A project can be associated 
with any number of samples.
=end

class ProjectsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections, :only => [:new, :new_inline, :create, :create_inline,
                                                     :edit, :update]

=begin rapidoc
url:: /projects
method:: GET
example:: <%= SiteConfig.site_url %>/projects
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Project.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= Project.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of all summary information on all projects

Get a list of all projects, which doesn't have all the details that are 
available when retrieving single projects (see GET /projects/[project id]).
=end
  
  def index
    @projects = Project.accessible_by(current_user)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @projects.
        collect{|x| x.summary_hash}
      }
      format.json { render :json => @projects.
        collect{|x| x.summary_hash}.to_json
      }
    end
  end

=begin rapidoc
url:: /projects/[project id]
method:: GET
example:: <%= SiteConfig.site_url %>/projects/5.json
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Project.find(:first).detail_hash) %>
xml:: <%= Project.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular project

Get detailed information about a single project.
=end
  
  def show
    @project = Project.accessible_by(current_user).find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @project.detail_hash }
      format.json  { render :json => @project.detail_hash }
    end
  end
  
  def new
    @project = Project.new
  end

  def new_inline
    @project = Project.new
    render :partial => 'new_inline'
  end
  
  def create
    @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created.'
      redirect_to projects_url
    else
      render :action => 'new'
    end
  end

  def create_inline
    @project = Project.new(params[:project])
    if @project.save
      @projects = Project.accessible_to_user(current_user)
      render :partial => 'sample_sets/projects'
    else
      render :partial => 'new_inline'
    end
  end
  
  def edit
    @project = Project.accessible_by(current_user).find(params[:id])
  end

  def update
    @project = Project.accessible_by(current_user).find(params[:id])
    
    begin
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        redirect_to projects_url
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this project."
      @project = Project.accessible_by(current_user).find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy    
    Project.accessible_by(current_user).find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end

  def grid
    projects = Project.accessible_by(current_user).find(:all) do
      if params[:_search] == "true"
        name      =~ "%#{params[:name]}%" if params[:name].present?
        budget    =~ "%#{params[:budget]}%" if params[:budget].present?
        lab_group =~ "%#{params[:lab_group]}%" if params[:lab_group].present?
        active    =~ "%#{params[:active]}%" if params[:active].present?
      end
      lab_group_id === current_user.get_lab_group_ids
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => projects.to_jqgrid_json(
      [:name, :budget, :lab_group_name, :active_yes_or_no], 
      params[:page], params[:rows], projects.total_entries
    )
  end

  private
  
  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
  end
end
