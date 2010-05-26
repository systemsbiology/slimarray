class CreateQcStatistics < ActiveRecord::Migration
  def self.up
    create_table :qc_statistics do |t|
      t.integer :qc_set_id
      t.integer :qc_metric_id
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :qc_statistics
  end
end
