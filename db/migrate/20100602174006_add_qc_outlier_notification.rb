class AddQcOutlierNotification < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :notify_of_qc_outliers, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :user_profiles, :notify_of_qc_outliers
  end
end
