class MoveProjectToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :project_id, :integer

    Sample.reset_column_information
    Sample.all.each do |sample|
      # ugly, but just for the sake of the migration
      sample.update_attributes( :project_id => sample.try(:microarray).try(:chip).try(:sample_set).try(:project_id) )
    end

    remove_column :sample_sets, :project_id
  end

  def self.down
    raise "Migration can't be safely reversed"
  end
end
