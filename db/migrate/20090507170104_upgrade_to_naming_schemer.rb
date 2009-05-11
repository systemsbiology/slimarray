class UpgradeToNamingSchemer < ActiveRecord::Migration
  def self.up
    rename_column :naming_elements, :include_in_sample_name, :include_in_sample_description
  end

  def self.down
    rename_column :naming_elements, :include_in_sample_description, :include_in_sample_name
  end
end
