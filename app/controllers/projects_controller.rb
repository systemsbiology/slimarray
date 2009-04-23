class ProjectsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def index
    @projects = Project.find(:all, :order => "name ASC")
    
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @projects }
      format.json { render :json => @projects }
    end
  end

  def show
    @project = Project.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @project.detail_hash }
      format.json  { render :json => @project.detail_hash }
    end
  end
  
  def new
    populate_arrays_from_tables
    @project = Project.new
  end

  def create
    populate_arrays_from_tables

    @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created.'
      redirect_to projects_url
    else
      render :action => 'new'
    end
  end

  def edit
    populate_arrays_from_tables
    @project = Project.find(params[:id])
  end

  def update
    populate_arrays_from_tables
    
    @project = Project.find(params[:id])
    
    begin
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        redirect_to projects_url, :id => @project
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this project."
      @project = Project.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy    
    Project.find(params[:id]).destroy
    redirect_to projects_url
  end

  private
  def populate_arrays_from_tables
    # Administrators and staff can see all projects, otherwise users
    # are restricted to seeing only projects for lab groups they belong to
    if(current_user.staff_or_admin?)
      @lab_groups = LabGroup.find(:all, :order => "name ASC")
    else
      @lab_groups = current_user.lab_groups
    end
  end
end
