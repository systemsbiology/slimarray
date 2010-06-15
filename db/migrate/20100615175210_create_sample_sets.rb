class CreateSampleSets < ActiveRecord::Migration
  def self.up
    create_table :sample_sets do |t|
      t.timestamps
    end

    add_column :samples, :sample_set_id, :integer
  end

  def self.down
    drop_table :sample_sets
    remove_column :samples, :sample_set_id
  end
end
