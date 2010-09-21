class AddSampleServiceOptionId < ActiveRecord::Migration
  def self.up
    add_column :samples, :service_option_id, :integer
  end

  def self.down
    remove_column :samples, :service_option_id
  end
end
