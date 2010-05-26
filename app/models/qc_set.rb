class QcSet < ActiveRecord::Base
  belongs_to :hybridization
  has_many :qc_statistics

  validates_presence_of :hybridization_id
  validates_associated :hybridization
end
