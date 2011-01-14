class AddMatchLabelIdToLabel < ActiveRecord::Migration
  def self.up
    add_column :labels, :match_label_id, :integer
  end

  def self.down
    remove_column :labels, :match_label_id
  end
end
