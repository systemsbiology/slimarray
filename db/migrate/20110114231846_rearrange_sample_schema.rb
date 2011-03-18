class RearrangeSampleSchema < ActiveRecord::Migration
  def self.up
    puts "-- removing orphan microarrays and chips"
    Microarray.all.each do |microarray|
      # Prior to the schema change, microarrays should not exist
      # without hybridizations
      if !Hybridization.find_by_microarray_id(microarray.id)
        chip = Chip.find_by_id(microarray.chip_id)
        chip.destroy if chip
        microarray.destroy
      end
    end
    Chip.all.each do |chip|
      if chip.microarrays.size == 0
        chip.destroy
      end
    end

    puts "-- associate samples with microarrays instead of hybridizations"
    add_column :samples, :microarray_id, :integer
    Sample.reset_column_information
    Sample.find(:all, :conditions => "hybridization_id IS NOT NULL").each do |sample|
      hybridization = Hybridization.find(sample.hybridization_id)
      sample.update_attribute('microarray_id', hybridization.microarray_id)
    end
    remove_column :samples, :hybridization_id

    # Samples without a microarray now get a microarray/chip
    puts "-- samples without a microarray/chip get one"
    Sample.find(:all, :conditions => "microarray_id IS NULL").each do |sample|
      chip = Chip.create
      microarray = Microarray.create(:chip_id => chip.id)
      sample.update_attribute('microarray_id', microarray.id)
    end

    # Sample sets have chips instead of samples
    puts "-- associate sample sets with chips instead of samples"
    add_column :chips, :sample_set_id, :integer
    Chip.reset_column_information
    Sample.find(:all, :conditions => "sample_set_id IS NOT NULL").each do |sample|
      # Don't want to rely on associations here so there are a lot of lookups by id
      sample_set = SampleSet.find(sample.sample_set_id)
      microarray = Microarray.find(sample.microarray_id)
      chip = microarray.chip
      chip.update_attribute('sample_set_id', sample_set.id)
    end
    remove_column :samples, :sample_set_id

    # Columns that are moving to sample_sets from samples
    add_column :sample_sets, :project_id, :integer
    add_column :sample_sets, :chip_type_id, :integer
    add_column :sample_sets, :naming_scheme_id, :integer
    add_column :sample_sets, :service_option_id, :integer
    add_column :sample_sets, :submission_date, :date
    add_column :sample_sets, :submitted_by, :string
    add_column :sample_sets, :submitted_by_id, :integer
    add_column :chips, :status, :string, :null => false, :default => "submitted"
    add_column :sample_sets, :ready_for_processing, :boolean, :null => false, :default => true
    SampleSet.reset_column_information
    Chip.reset_column_information

    # All chips without a sample set get one now
    puts "-- create a sample set for each chip lacking one"
    Chip.find(:all, :conditions => "sample_set_id IS NULL").each do |chip|
      sample = chip.microarrays.first.samples.first
      sample_set = SampleSet.create(
        :project_id => sample.project_id,
        :chip_type_id => sample.chip_type_id,
        :naming_scheme_id => sample.naming_scheme_id,
        :service_option_id => sample.service_option_id,
        :submission_date => sample.submission_date,
        :submitted_by => sample.sbeams_user,
        :ready_for_processing => sample.ready_for_processing
      )
      chip.update_attribute('sample_set_id', sample_set.id)
    end

    # Move some attributes from samples to sample sets
    puts "-- move attributes from sample to sample set"
    Sample.all.each do |sample|
      microarray = Microarray.find(sample.microarray_id)

      chip = Chip.find(microarray.chip_id)
      chip.update_attributes(:status => sample.status)

      sample_set = SampleSet.find(chip.sample_set_id)
      sample_set.update_attributes(
        :project_id => sample.project_id,
        :chip_type_id => sample.chip_type_id,
        :naming_scheme_id => sample.naming_scheme_id,
        :service_option_id => sample.service_option_id,
        :submission_date => sample.submission_date,
        :submitted_by => sample.sbeams_user,
        :ready_for_processing => sample.ready_for_processing
      )
    end
    remove_column :samples, :project_id
    remove_column :samples, :chip_type_id
    remove_column :samples, :naming_scheme_id
    remove_column :samples, :service_option_id
    remove_column :samples, :submission_date
    remove_column :samples, :sbeams_user
    remove_column :samples, :status
    remove_column :samples, :ready_for_processing

    # Find associated user where available
    users_by_login = User.all_by_login
    SampleSet.all.each do |set|
      user = users_by_login[set.submitted_by]
      set.update_attributes(:submitted_by_id => user.id) if user
    end

    add_column :chips, :hybridization_date, :date
    add_column :chips, :chip_number, :integer
    add_column :microarrays, :raw_data_path, :string
    add_column :microarrays, :charge_set_id, :integer
    Chip.reset_column_information
    Microarray.reset_column_information
    Hybridization.find(:all, :include => {:microarray => :chip}).each do |hybridization|
      microarray = Microarray.find(hybridization.microarray_id)
      chip = Chip.find(microarray.chip_id)
      chip.update_attributes(
        :hybridization_date => hybridization.hybridization_date,
        :chip_number => hybridization.chip_number
      )
      microarray.update_attributes(
        :raw_data_path => hybridization.raw_data_path,
        :charge_set_id => hybridization.raw_data_path
      )
    end
    drop_table :hybridizations
  end

  def self.down
    raise "This migration is not reversible"
  end
end
