class AddAppProfileFields < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :current_naming_scheme_id, :integer
  end

  def self.down
    remove_column :user_profiles, :current_naming_scheme_id
  end
end
