class AddProjectActive < ActiveRecord::Migration
  def self.up
    add_column :projects, :active, :boolean, :default => true
  end

  def self.down
    remove_column :projects, :active
  end
end
