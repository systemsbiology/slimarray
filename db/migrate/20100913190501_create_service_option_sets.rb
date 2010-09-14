class CreateServiceOptionSets < ActiveRecord::Migration
  def self.up
    create_table :service_option_sets do |t|
      t.string :name

      t.timestamps
    end

    create_table :service_option_sets_service_options, :id => false do |t|
      t.integer :service_option_id
      t.integer :service_option_set_id
    end

    add_column :chip_types, :service_option_set_id, :integer
  end

  def self.down
    drop_table :service_option_sets
    drop_table :service_option_sets_service_options
    remove_column :chip_types, :service_option_set_id
  end
end
