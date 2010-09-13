class Hybridization < ActiveRecord::Base
  has_many :samples
  belongs_to :charge_set
  belongs_to :charge_template
  belongs_to :microarray

  validates_presence_of :hybridization_date
  validates_numericality_of :chip_number

  def validate_on_create
    # make sure date / chip number / array number combo is unique
    other_hybridizations = 
      Hybridization.find_all_by_hybridization_date_and_chip_number(hybridization_date, chip_number)
    other_hybridizations.each do |other_hybridization|
      if(microarray.array_number == other_hybridization.microarray.array_number &&
         microarray.chip.name == other_hybridization.microarray.chip.name)
        errors.add("Duplicate hybridization hybridization date / chip number / array number")
      end
    end
  end
  
  def before_create
    populate_raw_data_path
  end

  def after_create
    # mark samples as hybridized
    samples.each do |s|
      s.update_attributes(:status => "hybridized")
    end

    create_gcos_import_file if SiteConfig.create_gcos_files?
    create_agcc_array_file if SiteConfig.create_agcc_files?
  end

  def after_destroy
    samples.each do |s|
      s.update_attributes(:status => "submitted")
    end
  end

  def sample_names
    ordered_samples = samples.sort{|a,b| a.label.name <=> b.label.name}
    ordered_samples.collect {|s| s.sample_name}.join("_v_")
  end

  def short_sample_names
    samples.collect {|s| s.short_sample_name}.join(", ")
  end

  def sbeams_user
    samples.first && samples.first.sbeams_user
  end

  def project_name
    samples.first && samples.first.project.name
  end

  def populate_raw_data_path
    # don't overwrite an existing path
    return if raw_data_path

    raw_data_root_path = SiteConfig.raw_data_root_path

    sample = samples.first

    return unless sample.chip_type.platform &&
      sample.chip_type.platform.name == "Affymetrix" &&
      raw_data_root_path

    hybridization_year_month = hybridization_date.year.to_s + 
                               ("%02d" % hybridization_date.month)
    hybridization_date_number_string = hybridization_year_month +
                         ("%02d" % hybridization_date.day) + "_" + 
                         ("%02d" % chip_number)
    self.raw_data_path = raw_data_root_path + "/" + hybridization_year_month + "/" +
                                  hybridization_date_number_string + "_" + 
                                  sample.sample_name + ".CEL"
  end

  def self.populate_all_raw_data_paths
    Hybridization.all.each do |hybridization|
      hybridization.populate_raw_data_path
      hybridization.save
    end
  end

  def self.populate_raw_data_paths(hybridizations)
    for hybridization in hybridizations
      hybridization.populate_raw_data_path
      hybridization.save
    end
  end

  def self.record_as_chip_transactions(hybridizations)
    hybs_per_date_group_chip = Hash.new

    for hybridization in hybridizations
      date = hybridization.hybridization_date
      hybs_per_date_group_chip[date] ||= Hash.new

      sample = hybridization.samples.first
      lab_group_id = sample.project.lab_group_id
      hybs_per_date_group_chip[date][lab_group_id] ||= Hash.new
      
      chip_type_id = sample.chip_type_id
      hybs_per_date_group_chip[date][lab_group_id][chip_type_id] ||= 0
      hybs_per_date_group_chip[date][lab_group_id][chip_type_id] += 1
    end

    transactions = Array.new
    hybs_per_date_group_chip.each do |date, group_hash|
      group_hash.each do |lab_group_id, chip_hash|
        chip_hash.each do |chip_type_id, hybridization_count|
          chip_type = ChipType.find(chip_type_id)
          chips_used = hybridization_count / chip_type.arrays_per_chip

          transactions << ChipTransaction.create(
            :lab_group_id => lab_group_id,
            :chip_type_id => chip_type_id,
            :date => date,
            :description => 'Hybridized on ' + date.to_s,
            :used => chips_used
          )
        end
      end
    end      

    return transactions
  end

  def create_gcos_import_file
    # assume 1 sample since GCOS files are Affy-specific
    sample = samples.first

    # only make hyb info record for GCOS if it's an affy array
    return unless sample.chip_type.platform && sample.chip_type.platform.name == "Affymetrix"

    # open an output file for writing
    gcos_file = File.new(SiteConfig.gcos_output_path + "/" + hybridization_date_number_string +
                "_" + sample.sample_name + ".txt", "w")

    # gather individual and group naming scheme info, if a naming scheme is being used
    if sample.naming_scheme_id != nil
      gcos_sample_info = Array.new
      gcos_experiment_info = Array.new

      # store the GCOS sample and experiment templates from the naming schemes
      gcos_sample_info << "SampleTemplate=" + sample.naming_scheme.name + "\n"
      gcos_experiment_info << "ExperimentTemplate=" + sample.naming_scheme.name + "\n"

      for sample_term in sample.sample_terms
        if(sample_term.naming_term.naming_element.group_element == true)
          gcos_sample_info << sample_term.naming_term.naming_element.name + "=" + sample_term.naming_term.term + "\n"
        else
          gcos_experiment_info << sample_term.naming_term.naming_element.name + "=" + sample_term.naming_term.term + "\n"
        end
      end

      for sample_text in sample.sample_texts
        if(sample_text.naming_element.group_element == true)
          gcos_sample_info << sample_text.naming_element.name + "=" + sample_text.text + "\n"
        else
          gcos_experiment_info << sample_text.naming_element.name + "=" + sample_text.text + "\n"
        end
      end
    # use default sample template of AffyCore if there's no naming scheme
    else
      gcos_file << "SampleTemplate=AffyCore\n"
    end

    # write out information needed by GCOS Object Importer tool
    gcos_file << "[SAMPLE]\n"
    gcos_file << "SampleName=" + sample.sample_group_name + "\n"
    gcos_file << "SampleType=" + Organism.find(sample.chip_type.organism_id).name + "\n"
    gcos_file << "SampleProject=" + sample.project.name + "\n"
    gcos_file << "SampleUser=affybot\n"
    gcos_file << "SampleUpdate=1\n"
    gcos_file << "Array User Name=" + sample.sbeams_user + "\n"

    # add any extra info from the naming scheme, if present
    if( gcos_sample_info != nil )
      for line in gcos_sample_info
        gcos_file << line
      end
    end

    gcos_file << "\n"
    gcos_file << "[EXPERIMENT]\n"
    gcos_file << "ExperimentName=" + hybridization_date_number_string + "_" + sample.sample_name + "\n"
    gcos_file << "ArrayType=" + ChipType.find(sample.chip_type_id).short_name + "\n"
    gcos_file << "ExperimentUser=affybot\n"
    gcos_file << "ExperimentUpdate=0\n"

    # add any extra info from the naming scheme, if present
    if( gcos_experiment_info != nil )
      for line in gcos_experiment_info
        gcos_file << line
      end
    end

    gcos_file.close
  end

  def create_agcc_array_file

    # assume 1 sample since AGCC files are Affy-specific
    sample = samples.first

    # only make hyb info record for GCOS if it's an affy array
    return unless sample.chip_type.platform && sample.chip_type.platform.name == "Affymetrix"

    chip_type_name = sample.chip_type.short_name
                         
    d = REXML::Document.new
    d.add_element("ArraySetFile", {"Type" => 'affymetrix-calvin-arraysetfile',
                                   "Version" => '1.0', "CreatedStep" => 'Other',
                                   "GUID" => Guid.new})
    pa = d.root.add_element("PhysicalArrays")
    pa.add_element("PhysicalArray", {"Type" => 'affymetrix-calvin-array',
                                      "MediaFileName" => chip_type_name + ".MEDIA",
                                      "MediaFileGUID" => chip_type_name + "_MEDIA",
                                      "MasterFileName" => chip_type_name + ".MASTER",
                                      "MasterFileGUID" => chip_type_name + "_MASTER",
                                      "LibraryPackageName" => sample.chip_type.library_package,
                                      "GUID" => Guid.new,
                                      "ArrayName" => (hybridization_date_number_string + "_" + sample.sample_name),
                                      "MediaType" => 'Cartridge'})

    agcc_file = File.new(SiteConfig.agcc_output_path + "/" + hybridization_date_number_string +
                  "_" + sample.sample_name + ".ARR", "w")

    d.write(agcc_file)
    agcc_file.close
  end

  def self.highest_chip_number(date)
      highest_chip_number_hyb = Hybridization.find(:first, 
        :conditions => {:hybridization_date => date},
        :order => "chip_number DESC"
      )
      if(highest_chip_number_hyb != nil)
        current_hyb_number = highest_chip_number_hyb.chip_number
      else
        current_hyb_number = 0
      end
  end

  def self.record_charges(hybridizations)  
    for hybridization in hybridizations
      # set up a charge set if needed
      unless(hybridization.charge_set)
        project = hybridization.samples.first.project

        charge_period = ChargePeriod.find(:last)
        charge_period = ChargePeriod.create(:name => "Default") unless charge_period

        charge_set = ChargeSet.find_or_create_by_charge_period_id_and_lab_group_id_and_name(
          :charge_period_id => charge_period.id,
          :lab_group_id => project.lab_group_id,
          :name => project.name
        )

        hybridization.update_attributes(:charge_set_id => charge_set.id)
      end

      template = ChargeTemplate.find(hybridization.charge_template_id)
      charge = Charge.create(:charge_set_id => hybridization.charge_set_id,
                             :date => hybridization.hybridization_date,
                             :description => hybridization.sample_names,
                             :chips_used => template.chips_used,
                             :chip_cost => template.chip_cost,
                             :labeling_cost => template.labeling_cost,
                             :hybridization_cost => template.hybridization_cost,
                             :qc_cost => template.qc_cost,
                             :other_cost => template.other_cost)
    end
  end

  def self.output_trace_images(hybridizations)
    for hybridization in hybridizations
      sample = hybridization.sample
      hybridization_year_month = hybridization.hybridization_date.year.to_s + ("%02d" % hybridization.hybridization_date.month)
      hybridization_date_number_string =  hybridization_year_month + ("%02d" % hybridization.hybridization_date.day) + 
                                          "_" + ("%02d" % hybridization.chip_number)
      chip_name = hybridization_date_number_string + "_" + sample.sample_name

      output_path = SiteConfig.quality_trace_dropoff + "/" + hybridization_year_month

      # output each quality trace image if it exists
      if( sample.starting_quality_trace != nil )
        copy_image_based_on_chip_name( sample.starting_quality_trace, output_path, chip_name + ".EGRAM_T.jpg" )
      end
      if( sample.amplified_quality_trace != nil )
        copy_image_based_on_chip_name( sample.amplified_quality_trace, output_path, chip_name + ".EGRAM_PF.jpg" )
      end
      if( sample.fragmented_quality_trace != nil )
        copy_image_based_on_chip_name( sample.fragmented_quality_trace, output_path, chip_name + ".EGRAM_F.jpg" )
      end
    end
  end
  
  def self.copy_image_based_on_chip_name(quality_trace, output_path, image_name)
    FileUtils.cp( "#{RAILS_ROOT}/public/" + quality_trace.image_path, output_path + "/" + image_name )
  end

private

  def hybridization_date_number_string
    return hybridization_date.year.to_s + ("%02d" % hybridization_date.month) +
                           ("%02d" % hybridization_date.day) + "_" + ("%02d" % chip_number)
  end
end
