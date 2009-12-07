class Microarray < ActiveRecord::Base
  belongs_to :chip
  has_one :hybridization
end
