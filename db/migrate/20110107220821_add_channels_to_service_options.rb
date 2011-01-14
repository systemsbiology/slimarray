class AddChannelsToServiceOptions < ActiveRecord::Migration
  def self.up
    add_column :service_options, :channels, :integer, :default => 1
  end

  def self.down
    remove_column :service_options, :channels
  end
end
