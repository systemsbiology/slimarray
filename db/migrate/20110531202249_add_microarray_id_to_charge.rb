class AddMicroarrayIdToCharge < ActiveRecord::Migration
  def self.up
    add_column :charges, :microarray_id, :integer
  end

  def self.down
    remove_column :charges, :microarray_id
  end
end
