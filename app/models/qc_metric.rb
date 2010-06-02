class QcMetric < ActiveRecord::Base
  has_many :qc_statistics
  has_many :qc_thresholds

  validates_uniqueness_of :name
  validates_presence_of :name
end
