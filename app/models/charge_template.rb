class ChargeTemplate < ActiveRecord::Base
  has_many :hybridizations

  belongs_to :platform

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_numericality_of :chips_used
  validates_numericality_of :chip_cost
  validates_numericality_of :labeling_cost
  validates_numericality_of :hybridization_cost
  validates_numericality_of :qc_cost
  validates_numericality_of :other_cost
end
