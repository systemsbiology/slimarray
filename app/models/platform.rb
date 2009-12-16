class Platform < ActiveRecord::Base
  has_many :chip_types
  has_many :charge_templates
  
  belongs_to :default_label, :class_name => "Label"

  validates_uniqueness_of :name
end
