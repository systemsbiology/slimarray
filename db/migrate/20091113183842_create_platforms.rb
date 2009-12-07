class CreatePlatforms < ActiveRecord::Migration
  def self.up
    create_table :platforms do |t|
      t.string :name, :null => false
      t.boolean :has_multi_array_chips, :null => false, :default => false
      t.boolean :uses_chip_numbers, :null => false, :default => false
      t.boolean :multiple_labels, :null => false, :default => true
      t.integer :default_label_id, :null => false
      t.string :raw_data_type, :null => false, :default => "Unknown"

      t.timestamps
    end

    add_index :platforms, :default_label_id
  end

  def self.down
    drop_table :platforms
  end
end
