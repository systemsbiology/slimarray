class Chip < ActiveRecord::Base
  belongs_to :sample_set

  has_many :microarrays
  accepts_nested_attributes_for :microarrays
end
