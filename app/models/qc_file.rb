class QcFile < ActiveRecord::Base
  belongs_to :qc_set

  validates_presence_of :path
  validates_associated :qc_set
end
