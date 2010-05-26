class QcFile < ActiveRecord::Base
  belongs_to :qc_set

  validates_presence_of :qc_set_id, :path
  validates_associated :qc_set
end
