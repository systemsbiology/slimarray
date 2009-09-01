class InventoryCheck < ActiveRecord::Base
  belongs_to :lab_group
  belongs_to :chip_type
  
  validates_numericality_of :number_expected
  validates_numericality_of :number_counted

  cattr_accessor :cached_lab_groups_by_id

  def lab_group_name
    @@cached_lab_groups_by_id ||= LabGroup.all_by_id

    return @@cached_lab_groups_by_id[lab_group_id].name
  end
end
