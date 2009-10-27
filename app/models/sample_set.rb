class SampleSet < ActiveRecord::BaseWithoutTable
  column :submission_date, :date
  column :number_of_samples, :string
  column :project_id, :integer
  column :naming_scheme_id, :integer
  column :chip_type_id, :integer
  column :sbeams_user, :string

  validates_numericality_of :number_of_samples, :greater_than_or_equal_to => 1
  validates_presence_of :chip_type_id, :project_id
  
  has_many :samples
  
  belongs_to :naming_scheme
  
  def self.new(attributes=nil)
    super(attributes)
  end

  def project
    return Project.find(project_id)
  end

  def chip_type
    return ChipType.find(chip_type_id)
  end
end
