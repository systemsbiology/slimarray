class QcThreshold < ActiveRecord::Base
  belongs_to :platform
  belongs_to :qc_metric

  validates_presence_of :platform_id, :qc_metric_id
  validates_associated :platform, :qc_metric
end
