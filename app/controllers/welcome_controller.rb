class WelcomeController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required, :only => [ :staff ]
  
  def index
    if(current_user.staff_or_admin?)
      redirect_to :action => 'staff'
    else
      redirect_to :action => 'home'
    end
  end

  def home
    # Admins get their own home page
    if(current_user.staff_or_admin?)
      redirect_to :action => 'staff'
    end
    
    # get all possible naming schemes
    @naming_schemes = NamingScheme.find(:all)

    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?

    @lab_groups = current_user.lab_groups
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end

  def staff
    # get all possible naming schemes
    @naming_schemes = NamingScheme.find(:all)

    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
    
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end

  def grid
    # Make an array of the accessible lab group ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    lab_group_ids = current_user.get_lab_group_ids
    projects = Project.find(:all, :conditions => [ "lab_group_id IN (?)", lab_group_ids],
                              :order => "name ASC")
    project_ids = projects.collect{|x| x.id}
    #samples = Sample.find(:all, :conditions => [ "project_id IN (?) AND status = ?", project_ids, 'submitted' ],
    #                          :order => "samples.id ASC")

    samples = Sample.find(:all, :include => :project) do
      if params[:_search] == "true"
        submission_date   =~ "%#{params[:submission_date]}%" if params[:submission_date].present?                
        short_sample_name =~ "%#{params["short_sample_name"]}%" if params["short_sample_name"].present?
        sample_name       =~ "%#{params[:sample_name]}%" if params[:sample_name].present?                
        sbeams_user       =~ "%#{params[:sbeams_user]}%" if params[:sbeams_user].present?                
        project.name      =~ "%#{params["projects.name"]}%" if params["projects.name"].present?                
      end
      status == "submitted"
      "project_id IN (#{project_ids})"
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => samples.to_jqgrid_json(
      [:submission_date, :short_sample_name, :sample_name, :sbeams_user, "project.name"], 
      params[:page], params[:rows], samples.total_entries
    )
  end
end
