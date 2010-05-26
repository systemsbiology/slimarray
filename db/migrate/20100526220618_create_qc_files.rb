class CreateQcFiles < ActiveRecord::Migration
  def self.up
    create_table :qc_files do |t|
      t.integer :qc_set_id
      t.string :path

      t.timestamps
    end
  end

  def self.down
    drop_table :qc_files
  end
end
