class AddChipTypeLibraryPackage < ActiveRecord::Migration
  def self.up
    add_column :chip_types, :library_package, :string
  end

  def self.down
    remove_column :chip_types, :library_package
  end
end
