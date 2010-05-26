class CreateQcThresholds < ActiveRecord::Migration
  def self.up
    create_table :qc_thresholds do |t|
      t.integer :platform_id
      t.integer :qc_metric_id
      t.float :lower_limit
      t.float :upper_limit
      t.string :should_contain
      t.string :should_not_contain

      t.timestamps
    end
  end

  def self.down
    drop_table :qc_thresholds
  end
end
