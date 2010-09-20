class AddApprovalRequirements < ActiveRecord::Migration
  def self.up
    add_column :lab_group_profiles, :require_manager_approval, :boolean
    add_column :lab_group_profiles, :manager_approval_minimum, :float
    add_column :lab_group_profiles, :require_investigator_approval, :boolean
    add_column :lab_group_profiles, :investigator_approval_minimum, :float
  end

  def self.down
    remove_column :lab_group_profiles, :require_manager_approval
    remove_column :lab_group_profiles, :manager_approval_minimum
    remove_column :lab_group_profiles, :require_investigator_approval
    remove_column :lab_group_profiles, :investigator_approval_minimum
  end
end
