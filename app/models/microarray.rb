class Microarray < ActiveRecord::Base
  belongs_to :chip
  has_one :hybridization

  def name
    hybridization.sample_names
  end
end
