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
    
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?

    @lab_groups = current_user.lab_groups
    @chip_types = ChipType.find(:all, :order => "name ASC")

    @sample_sets = SampleSet.accessible_to_user_with_status(current_user, "submitted")
  end

  def staff
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
    
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")

    @sample_sets = SampleSet.find(:all, :include => [:service_option, {:chips => {:microarrays => :samples}}], :conditions => "chips.status = 'submitted'")
  end
end
