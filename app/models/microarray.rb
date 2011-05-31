class Microarray < ActiveRecord::Base
  extend ApiAccessible
  include SharedMethods

  belongs_to :chip

  has_many :samples

  has_one :hybridization

  def samples_attributes=(attributes)
    sort_attributes_numerically(attributes).each do |key, sample_attributes|
      schemed_params = sample_attributes.delete(:schemed_name)
      sample = samples.build(sample_attributes)
      sample.microarray ||= self
      sample.schemed_name = schemed_params if schemed_params
    end
  end

  api_reader :array_number

  def name
    ordered_samples = samples.sort{|a,b| a.label.name <=> b.label.name}
    ordered_samples.collect {|s| s.sample_name}.join("_v_")
  end

  api_reader :chip_name
  def chip_name
    chip.name
  end

  api_reader :scheme
  def scheme
    chip.sample_set.naming_scheme_id
  end

  api_reader :lab_group
  def lab_group
    chip.sample_set.project.lab_group_id
  end

  api_reader :project
  def project
    chip.sample_set.project_id
  end

  api_reader :schemed_descriptors
  def schemed_descriptors
    descriptors = Hash.new

    sample = samples.first
    return [] unless sample

    sample.sample_terms.find(:all, :order => "term_order ASC").each do |term|
      descriptors[term.naming_term.naming_element.name] = term.naming_term.term
    end

    sample.sample_texts.all.each do |text|
      descriptors[text.naming_element.name] = text.text
    end

    return descriptors
  end

  api_reader :raw_data_path

  api_reader :platform_name
  def platform_name
    chip.sample_set.chip_type.platform.name
  end

  api_reader :hybridization_date
  def hybridization_date
    chip.hybridization_date
  end

  def sample_number
    samples.size
  end

  def self.custom_find(user, params)
    # Fields that can be included in the SQL query
    query_fields = {
      "project_id" => "sample_sets.project_id",
      "naming_scheme_id" => "sample_sets.naming_scheme_id",
      "lab_group_id" => "projects.lab_group_id"
    }

    conditions = "projects.lab_group_id IN (" + user.get_lab_group_ids.join(",") + ")"
    query_fields.each do |key, value|
      if params.has_key? key
        if params[key] == "nil"
          conditions += " AND #{value} IS NULL"
        else
          conditions += " AND #{value} = #{params[key]}"
        end
      end
    end

    microarrays = find(:all, :include => {
        :chip => {:sample_set => [{:chip_type => :platform}, :project, :naming_scheme]},
        :samples => :label,
      },
      :conditions => conditions)

    # A reload is needed to see the proper sample_number for arrays. This only appears to
    # be a problem when conditions are used on associations occurring after :samples.
    # Not sure if this is an ActiveRecord or MySQL or SQL thing.
    microarrays = microarrays.each {|m| m.reload}

    # Fields that have to be filtered in a secondary step
    filter_fields = ["sample_number"]

    filter_fields.each do |field|
      if params.has_key? field
        microarrays = microarrays.select{|array| array.send(field).to_s == params[field]}
      end
    end

    return microarrays
  end

  def summary_hash(with)
    @site_url ||= SiteConfig.site_url

    hash = {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :uri => "#{@site_url}/microarrays/#{id}"
    }

    with.split(",").each do |key|
      key = key.to_sym

      if Microarray.api_methods.include? key
        hash[key] = self.send(key)
      end
    end

    return hash
  end

  def sample_ids=(ids)
    # clear out old samples
    samples.clear

    # add selected samples
    ids.each_value{|id| samples << Sample.find(id) unless id == "0"}
  end

  def create_gcos_import_file
    # assume 1 sample since GCOS files are Affy-specific
    sample = samples.first

    # only make hyb info record for GCOS if it's an affy array
    return unless chip.sample_set && chip.sample_set.chip_type.platform && chip.sample_set.chip_type.platform.name == "Affymetrix"

    # open an output file for writing
    gcos_file = File.new(SiteConfig.gcos_output_path + "/" + chip.hybridization_date_number_string +
                "_" + sample.sample_name + ".txt", "w")

    # gather individual and group naming scheme info, if a naming scheme is being used
    if chip.sample_set.naming_scheme_id != nil
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
    gcos_file << "SampleType=" + Organism.find(chip.sample_set.chip_type.organism_id).name + "\n"
    gcos_file << "SampleProject=" + chip.sample_set.project.name + "\n"
    gcos_file << "SampleUser=affybot\n"
    gcos_file << "SampleUpdate=1\n"
    gcos_file << "Array User Name=" + chip.sample_set.submitted_by + "\n"

    # add any extra info from the naming scheme, if present
    if( gcos_sample_info != nil )
      for line in gcos_sample_info
        gcos_file << line
      end
    end

    gcos_file << "\n"
    gcos_file << "[EXPERIMENT]\n"
    gcos_file << "ExperimentName=" + chip.hybridization_date_number_string + "_" + sample.sample_name + "\n"
    gcos_file << "ArrayType=" + chip.sample_set.chip_type.short_name + "\n"
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

    chip_type = chip.sample_set.chip_type

    # only make hyb info record for GCOS if it's an affy array
    return unless chip_type.platform && chip_type.platform.name == "Affymetrix"

    chip_type_name = chip_type.short_name
                         
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
                                      "LibraryPackageName" => chip_type.library_package,
                                      "GUID" => Guid.new,
                                      "ArrayName" => (chip.hybridization_date_number_string + "_" + sample.sample_name),
                                      "MediaType" => 'Cartridge'})

    agcc_file = File.new(SiteConfig.agcc_output_path + "/" + chip.hybridization_date_number_string +
                  "_" + sample.sample_name + ".ARR", "w")

    d.write(agcc_file)
    agcc_file.close
  end

  def record_charge
    # set up a charge set if needed
    project = chip.sample_set.project

    charge_period = ChargePeriod.find(:last)
    charge_period = ChargePeriod.create(:name => "Default") unless charge_period

    charge_set = ChargeSet.find_or_create_by_charge_period_id_and_lab_group_id_and_name(
      :charge_period_id => charge_period.id,
      :lab_group_id => project.lab_group_id,
      :name => project.name
    )

    update_attributes(:charge_set_id => charge_set.id)

    service_option = chip.sample_set.service_option || ServiceOption.new

    # need to correct for sample number since costs are per sample, not array
    sample_number = samples.size
    charge = Charge.create(:charge_set_id => charge_set_id,
                           :date => chip.hybridization_date,
                           :description => name,
                           :chips_used => 1,
                           :chip_cost => service_option.chip_cost * sample_number,
                           :labeling_cost => service_option.labeling_cost * sample_number,
                           :hybridization_cost => service_option.hybridization_cost * sample_number,
                           :qc_cost => service_option.qc_cost * sample_number,
                           :other_cost => service_option.other_cost * sample_number)
  end
end
