class IncreaseSampleNameLength < ActiveRecord::Migration
  def self.up
    change_column :samples, :sample_name, :string, :limit => 255
  end

  def self.down
  end
end
