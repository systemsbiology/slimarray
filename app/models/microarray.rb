class Microarray < ActiveRecord::Base
  extend ApiAccessible

  belongs_to :chip

  has_many :samples
  accepts_nested_attributes_for :samples

  has_one :hybridization

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
    hybridization.samples.first.naming_scheme_id
  end

  api_reader :lab_group
  def lab_group
    hybridization.samples.first.project.lab_group_id
  end

  api_reader :project
  def project
    hybridization.samples.first.project_id
  end

  api_reader :schemed_descriptors
  def schemed_descriptors
    descriptors = Hash.new

    sample = hybridization.samples.first

    sample.sample_terms.find(:all, :order => "term_order ASC").each do |term|
      descriptors[term.naming_term.naming_element.name] = term.naming_term.term
    end

    sample.sample_texts.all.each do |text|
      descriptors[text.naming_element.name] = text.text
    end

    return descriptors
  end

  api_reader :raw_data_path
  def raw_data_path
    hybridization.raw_data_path
  end

  api_reader :platform_name
  def platform_name
    hybridization.samples.first.chip_type.platform.name
  end

  api_reader :hybridization_date
  def hybridization_date
    hybridization.hybridization_date
  end

  def sample_number
    hybridization.samples.size
  end

  def self.custom_find(user, params)
    # Fields that can be included in the SQL query
    query_fields = {
      "project_id" => "samples.project_id",
      "naming_scheme_id" => "samples.naming_scheme_id",
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
      :hybridization => {
        :samples => [:label, :project, {:chip_type => :platform}],
      }},
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
end
