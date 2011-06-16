class MoveProjectToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :project_id, :integer

    Sample.reset_column_information
    Sample.all.each do |sample|
      # ugly, but just for the sake of the migration
      sample_set = sample.try(:microarray).try(:chip).try(:sample_set)

      # go through attributes since project_id is now an attr_accessor and won't give the value
      # that's in the database
      sample.update_attributes( :project_id => sample_set.attributes["project_id"] ) if sample_set
    end

    remove_column :sample_sets, :project_id
  end

  def self.down
    raise "Migration can't be safely reversed"
  end
end
