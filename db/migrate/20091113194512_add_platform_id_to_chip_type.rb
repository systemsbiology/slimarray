class AddPlatformIdToChipType < ActiveRecord::Migration
  def self.up
    add_column :chip_types, :platform_id, :integer
    add_index :chip_types, :platform_id

    biotin_label = Label.find_or_create_by_name("Biotin")
    affy_platform = Platform.find_or_create_by_name(
      :name => "Affymetrix", :uses_chip_numbers => true, :raw_data_type => "Affymetrix CEL",
      :multiple_labels => false, :default_label_id => biotin_label.id
    )
    ChipType.all.each do |t|
      t.update_attributes(:platform_id => affy_platform.id) if t.array_platform == "affy"
    end
    
    remove_column :chip_types, :array_platform    

    announce("You will now need to create appropriate platforms for your non-Affymetrix " +
             "chip types.")
  end

  def self.down
    add_column :chip_types, :array_platform, :string

    affy_platform = Platform.find_by_name("Affymetrix")
    ChipType.all.each do |t|
      if t.platform == affy_platform
        t.update_attributes(:array_platform => "affy") 
      else
        t.update_attributes(:array_platform => "nonaffy")
      end
    end
    
    remove_index :chip_types, :platform_id
    remove_column :chip_types, :platform_id    
  end
end
