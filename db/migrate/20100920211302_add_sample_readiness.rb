class AddSampleReadiness < ActiveRecord::Migration
  def self.up
    add_column :samples, :ready_for_processing, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :samples, :ready_for_processing
  end
end
