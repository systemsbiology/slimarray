class AddSearchingIndices < ActiveRecord::Migration
  def self.up
    add_index :samples, :submission_date
    add_index :chip_types, :organism_id
    add_index :samples, :naming_scheme_id
    add_index :inventory_checks, :lab_group_id
    add_index :inventory_checks, :chip_type_id
  end

  def self.down
    remove_index :samples, :submission_date
    remove_index :chip_types, :organism_id
    remove_index :samples, :naming_scheme_id
    remove_index :inventory_checks, :lab_group_id
    remove_index :inventory_checks, :chip_type_id
  end
end
