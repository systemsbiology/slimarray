class UserProfile < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id
           
  named_scope :notify_of_new_samples,
    :conditions => {:notify_of_new_samples => true}
  named_scope :managers, :conditions => {:role => "manager"}
  named_scope :investigators, :conditions => {:role => "investigator"}
  
  # Manually provide a list of column names that should be shown in the users/index view, since 
  # ActiveResource doesn't seem to provide an easy way to do this.
  #
  # By default this include 'role' to allow role-based access
  class << self; attr_accessor :index_columns end
  @index_columns = ['role']

  def before_save
    # make the first user to log in the admin
    if(UserProfile.count == 0)
      self.role = "admin"
    end
  end

  def detail_hash
    return {}
  end
  
  def self.notify_of_qc_outliers
    UserProfile.find(:all, :conditions => {:notify_of_qc_outliers => true})
  end

  def self.notify_of_low_inventory
    UserProfile.find(:all, :conditions => {:notify_of_low_inventory => true})
  end

  ###############################################################################################
  # Authorization:
  #
  # By default a user's role is determined by looking at the column 'role' in the UserProfile 
  # model
  ###############################################################################################
  
  def staff_or_admin?
    role == "staff" || role == "admin"
  end
 
  def admin?
    role == "admin"
  end

  def manager?
    role == "manager"
  end

  def investigator?
    role == "investigator"
  end
end
