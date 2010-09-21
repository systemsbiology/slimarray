class AddUserProfileSubmissionNotification < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :notify_of_new_samples, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :user_profiles, :notify_of_new_samples
  end
end
