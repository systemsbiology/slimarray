class CreateServiceOptions < ActiveRecord::Migration
  def self.up
    create_table :service_options do |t|
      t.string :name
      t.string :notes
      t.float :chip_cost
      t.float :labeling_cost
      t.float :hybridization_cost
      t.float :qc_cost
      t.float :other_cost

      t.timestamps
    end
  end

  def self.down
    drop_table :service_options
  end
end
