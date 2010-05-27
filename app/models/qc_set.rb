class QcSet < ActiveRecord::Base
  belongs_to :hybridization
  has_many :qc_statistics
  has_many :qc_files

  validates_presence_of :hybridization_id
  validates_associated :hybridization

  def chip_name=(name)
    @chip_name = name

    lookup_hybridization
  end

  def array_number=(number)
    @array_number = number

    lookup_hybridization
  end

  def statistics=(statistic_hash)
    return unless statistic_hash

    statistic_hash.each do |name, value|
      metric = QcMetric.find_or_create_by_name(name)
      
      qc_statistics.build(:qc_metric => metric, :value => value)
    end
  end

  def file=(file_path)
    return unless file_path

    self.qc_files.build(:path => file_path)
  end

  private

  def lookup_hybridization
    return unless @chip_name && @array_number

    self.hybridization = Hybridization.find(
      :first,
      :include => {:microarray => :chip},
      :conditions => [ "chips.name = ? AND microarrays.array_number = ?",
                       @chip_name, @array_number ]
    )
  end
end
