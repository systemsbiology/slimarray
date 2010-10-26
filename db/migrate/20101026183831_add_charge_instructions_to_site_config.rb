class AddChargeInstructionsToSiteConfig < ActiveRecord::Migration
  def self.up
    add_column :site_config, :charge_instructions, :text
  end

  def self.down
    remove_column :site_config, :charge_instructions
  end
end
