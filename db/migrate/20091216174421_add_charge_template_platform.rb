class AddChargeTemplatePlatform < ActiveRecord::Migration
  def self.up
    add_column :charge_templates, :platform_id, :integer

    add_index :charge_templates, :platform_id
  end

  def self.down
    remove_index :charge_templates, :platform_id

    remove_column :charge_templates, :platform_id
  end
end
