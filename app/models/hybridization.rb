class Hybridization < ActiveRecord::Base
  belongs_to :sample
  belongs_to :charge_set
  belongs_to :charge_template

  validates_presence_of :hybridization_date
  validates_numericality_of :chip_number

  def validate_on_create
    # make sure date/chip number combo is unique
    if Hybridization.find_by_hybridization_date_and_chip_number(hybridization_date, chip_number)
      errors.add("Duplicate hybridization hybridization date/chip number")
    end
  end
  
  def self.populate_all_raw_data_paths
    hybridizations = Hybridization.find(:all)
    
    populate_raw_data_paths(hybridizations)
  end

  def self.populate_raw_data_paths(hybridizations)
    raw_data_root_path = SiteConfig.raw_data_root_path
 
    for hybridization in hybridizations
      sample = hybridization.sample
      # only do this for affy samples
      if( sample.chip_type.array_platform == "affy")
        hybridization_year_month = hybridization.hybridization_date.year.to_s + 
                                   ("%02d" % hybridization.hybridization_date.month)
        hybridization_date_number_string = hybridization_year_month +
                             ("%02d" % hybridization.hybridization_date.day) + "_" + 
                             ("%02d" % hybridization.chip_number)
        hybridization.raw_data_path = raw_data_root_path + "/" + hybridization_year_month + "/" +
                                      hybridization_date_number_string + "_" + 
                                      sample.sample_name + ".CEL"
        hybridization.save
      end
    end
  end

  def self.record_as_chip_transactions(hybridizations)
    hybs_per_group_chip = Hash.new(0)

    for hybridization in hybridizations
      sample = hybridization.sample
      hybridization_date_group_chip_key = hybridization.hybridization_date.to_s+
        "_"+sample.project.lab_group_id.to_s+"_"+sample.chip_type_id.to_s
      # if this hybridization_date/lab group/chip type combo hasn't been seen,
      # create a new object to track number of chips of this combo
      if hybs_per_group_chip[hybridization_date_group_chip_key] == 0
        hybs_per_group_chip[hybridization_date_group_chip_key] =
          ChipTransaction.new(
            :lab_group_id => sample.project.lab_group_id,
            :chip_type_id => sample.chip_type_id,
            :date => hybridization.hybridization_date,
            :description => 'Hybridized on ' + hybridization.hybridization_date.to_s,
            :used => 1
          )
      else
        hybs_per_group_chip[hybridization_date_group_chip_key][:used] += 1
      end
    end

    for hybridization_date_group_chip_key in hybs_per_group_chip.keys
      hybs_per_group_chip[hybridization_date_group_chip_key].save
    end

    return hybs_per_group_chip.values
  end

  def create_gcos_import_file
    # only make hyb info record for GCOS if it's an affy array
    if sample.chip_type.array_platform == "affy"
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
  end

  def create_agcc_array_file
    require 'guid'

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

private

  def hybridization_date_number_string
    return hybridization_date.year.to_s + ("%02d" % hybridization_date.month) +
                           ("%02d" % hybridization_date.day) + "_" + ("%02d" % chip_number)
  end
end
