class QcStatistic < ActiveRecord::Base
  belongs_to :qc_set
  belongs_to :qc_metric

  validates_presence_of :qc_set_id, :qc_metric_id
  validates_associated :qc_set, :qc_metric
end
