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
          projects << g.projects.find(:all, :conditions => {:active => true})
        else
          projects << g.projects
        end
      end
      
      # put it all down to a 1D Array
      projects.flatten!
      
      return projects.sort {|x,y| x.name <=> y.name }
    end  
  end
end
