class CreateQcSets < ActiveRecord::Migration
  def self.up
    create_table :qc_sets do |t|
      t.integer :hybridization_id

      t.timestamps
    end
  end

  def self.down
    drop_table :qc_sets
  end
end
