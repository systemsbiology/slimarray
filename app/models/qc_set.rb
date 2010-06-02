class QcSet < ActiveRecord::Base
  belongs_to :hybridization
  has_many :qc_statistics
  has_many :qc_files

  validates_presence_of :hybridization_id
  validates_associated :hybridization
  validates_uniqueness_of :hybridization_id

  def after_create
    Notifier.deliver_qc_outlier_notification(self) unless outlier_statistics.empty?
  end

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

  def outlier_statistics
    outliers = Array.new
    
    qc_statistics.each do |statistic|
      statistic.qc_metric.qc_thresholds.each do |threshold|
        if( threshold.lower_limit && statistic.value.to_f < threshold.lower_limit ||
            threshold.upper_limit && statistic.value.to_f > threshold.upper_limit ||
            threshold.should_contain && threshold.should_contain.length > 0 &&
              !statistic.value.include?(threshold.should_contain) ||
            threshold.should_not_contain && threshold.should_not_contain.length > 0 &&
              statistic.value.include?(threshold.should_not_contain) )
          outliers << statistic
        end
      end
    end

    outliers.uniq!

    return outliers
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
