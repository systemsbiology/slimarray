class AddUserProfileLowInventoryNotification < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :notify_of_low_inventory, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :user_profiles, :notify_of_low_inventory
  end
end
