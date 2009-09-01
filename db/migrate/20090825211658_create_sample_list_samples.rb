class CreateSampleListSamples < ActiveRecord::Migration
  def self.up
    create_table :sample_list_samples do |t|
      t.integer :sample_id
      t.integer :sample_list_id

      t.timestamps
    end
  end

  def self.down
    drop_table :sample_list_samples
  end
end
