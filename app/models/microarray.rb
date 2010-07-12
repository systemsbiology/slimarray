class Microarray < ActiveRecord::Base
  extend ApiAccessible

  belongs_to :chip
  has_one :hybridization

  api_reader :array_number

  def name
    hybridization.sample_names
  end

  api_reader :chip_name
  def chip_name
    chip.name
  end

  api_reader :scheme
  def scheme
    hybridization.samples.first.naming_scheme_id
  end

  api_reader :project
  def project
    hybridization.samples.first.project_id
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

  def self.custom_find(user, params)
    allowed_fields = {
      "project_id" => "samples.project_id",
      "naming_scheme_id" => "samples.naming_scheme_id",
      "lab_group_id" => "projects.lab_group_id"
    }

    conditions = "projects.lab_group_id IN (" + user.get_lab_group_ids.join(",") + ")"
    allowed_fields.each do |key, value|
      if params.include? key
        if params[key] == "nil"
          conditions += " AND #{value} IS NULL"
        else
          conditions += " AND #{value} = #{params[key]}"
        end
      end
    end

    find(:all, :include => { :hybridization => {:samples => :project} }, :conditions => conditions)
  end

  def summary_hash(with)
    hash = {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/microarrays/#{id}"
    }

    with.split(",").each do |key|
      key = key.to_sym

      if Microarray.api_methods.include? key
        hash[key] = self.send(key)
      end
    end

    return hash
  end
end
