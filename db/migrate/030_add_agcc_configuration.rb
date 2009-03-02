class AddAgccConfiguration < ActiveRecord::Migration
  def self.up
    add_column :site_config, :agcc_output_path, :string, :default => "/tmp"
    add_column :site_config, :create_agcc_files, :boolean, :default => false
  end

  def self.down
    remove_column :site_config, :agcc_output_path
    remove_column :site_config, :create_agcc_files
  end
end
