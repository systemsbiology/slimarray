class CreateMicroarrays < ActiveRecord::Migration
  def self.up
    create_table :microarrays do |t|
      t.integer :chip_id
      t.integer :array_number, :null => false, :default => 1

      t.timestamps
    end

    add_index :microarrays, :chip_id
  end

  def self.down
    drop_table :microarrays
  end
end
