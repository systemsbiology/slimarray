class CreateSampleLists < ActiveRecord::Migration
  def self.up
    create_table :sample_lists do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :sample_lists
  end
end
