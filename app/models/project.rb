class Project < ActiveRecord::Base
  has_many :samples
  belongs_to :lab_group
  
  validates_presence_of :name, :budget
  validates_length_of :name, :maximum => 250
  validates_length_of :budget, :maximum => 100
  
  def validate_on_create
    # make sure name/budget combo is unique
    if Project.find_by_name_and_budget(name, budget)
      errors.add("Multiple projects with same name and budget")
    end
  end
  
  cattr_accessor :cached_lab_groups_by_id

  def lab_group_name
    @@cached_lab_groups_by_id ||= LabGroup.all_by_id

    return @@cached_lab_groups_by_id[lab_group_id].name
  end

  def name_and_budget
    return "#{name} (#{budget})"
  end

  def self.accessible_to_user(user, active_only = false)
    # Administrators and staff can see all projects, otherwise users
    # are restricted to seeing only projects for lab groups they belong to
    if(user.staff_or_admin?)
      return Project.find(:all, :order => "name ASC")
    else
      projects = Array.new
      
      lab_groups = user.lab_groups
      lab_groups.each do |g|
        if(active_only)
          projects << Project.find(
            :all,
            :conditions => { :lab_group_id => g.id, :active => true },
            :order => "name ASC"
          )
        else
          projects << Project.find(
            :all,
            :conditions => { :lab_group_id => g.id },
            :order => "name ASC"
          )
        end
      end
      
      # put it all down to a 1D Array
      projects.flatten!
      
      return projects.sort {|x,y| x.name <=> y.name }
    end  
  end
  
  def self.for_lab_group(lab_group)
    return Project.find(:all, :conditions => {:lab_group_id => lab_group.id})    
  end

  def summary_hash
    return {
      :id => id,
      :name => name,
      :lab_group => lab_group_name,
      :lab_group_uri => "#{SiteConfig.site_url}/lab_groups/#{lab_group_id}",
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/projects/#{id}"
    }
  end
  
  def detail_hash
    samples = Sample.find(:all, :conditions => ["project_id =?", self.id])

    return {
      :id => id,
      :name => name,
      :lab_group => lab_group_name,
      :lab_group_uri => "#{SiteConfig.site_url}/lab_groups/#{lab_group_id}",
      :updated_at => updated_at,
      :sample_uris => samples.
        collect {|sample| "#{SiteConfig.site_url}/samples/#{sample.id}" }
    }
  end

  def active_yes_or_no
    active ? "Yes" : "No"
  end

  def samples
    Sample.find(:all, :conditions => ["project_id = ?", self.id])
  end
end
