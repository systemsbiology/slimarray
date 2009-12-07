class AddLabelIdToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :label_id, :integer
    add_index :samples, :label_id
  end

  def self.down
    remove_index :samples, :label_id
    remove_column :samples, :label_id
  end
end
