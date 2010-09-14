class ServiceOption < ActiveRecord::Base
  has_and_belongs_to_many :service_option_sets

  def total_cost
    chip_cost + labeling_cost + hybridization_cost + qc_cost + other_cost
  end
end
