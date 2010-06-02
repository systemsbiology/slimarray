class QcStatistic < ActiveRecord::Base
  belongs_to :qc_set
  belongs_to :qc_metric

  validates_presence_of :qc_metric_id, :value
  validates_associated :qc_set, :qc_metric

  validates_uniqueness_of :qc_metric_id, :scope => :qc_set_id
end
