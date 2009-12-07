class AddArraysPerChipToChipType < ActiveRecord::Migration
  def self.up
    add_column :chip_types, :arrays_per_chip, :integer, :null => false, :default => 1
  end

  def self.down
    remove_column :chip_types, :arrays_per_chip
  end
end
