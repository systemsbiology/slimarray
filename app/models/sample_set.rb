class SampleSet < ActiveRecord::Base
  # use validatable gem since we're validating attributes that aren't fields
  # in the sample_sets table (because they're transient)
  include Validatable

  attr_accessor :submission_date, :number_of_samples, :project_id, :naming_scheme_id, :integer,
    :chip_type_id, :sbeams_user, :label_id

  validates_numericality_of :number_of_samples
  validates_presence_of :chip_type_id, :project_id
  
  has_many :samples
  
  before_create :set_default_label

  def set_default_label
    if chip_type_id && chip_type_id != ""
      self.label_id = chip_type.platform.default_label_id
    end
  end

  def self.new(attributes=nil)
    parse_multi_field_date(attributes)

    sample_set = super
      
    # if attributes && attributes[:chip_type_id] && attributes[:chip_type_id] != ""
    #  sample_set.label_id = ChipType.find(attributes[:chip_type_id]).platform.default_label_id
    # end

    return sample_set
  end

  def project
    Project.find_by_id(project_id)
  end

  def chip_type
    ChipType.find_by_id(chip_type_id)
  end

  def platform
    return chip_type.platform
  end

  def naming_scheme
    NamingScheme.find_by_id(naming_scheme_id)
  end

  def self.parse_multi_field_date(attributes)
    return unless attributes

    # assume multi-field if year field is present
    if attributes["submission_date(1i)"]
      attributes["submission_date"] = Date.new(
        attributes.delete("submission_date(1i)").to_i,
        attributes.delete("submission_date(2i)").to_i,
        attributes.delete("submission_date(3i)").to_i
      )
    end
  end
end
