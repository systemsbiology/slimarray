class AddHybridizationMicroarrayId < ActiveRecord::Migration
  def self.up
    add_column :hybridizations, :microarray_id, :integer
    add_index :hybridizations, :microarray_id

    # migrate existing hybridizations so that they all have a Microarray and Chip, with 
    # the chip name using the <hyb date>_<chip number>_<sample name> format
    Hybridization.all.each do |h|
      chip_name = "#{h.hybridization_date.year.to_s}#{"%02d" % h.hybridization_date.month}" +
                  "#{"%02d" % h.hybridization_date.day}_#{"%02d" % h.chip_number}"
      chip = Chip.create(:name => chip_name)
      microarray = Microarray.create(:chip_id => chip.id, :array_number => 1)
      h.update_attributes(:microarray_id => microarray.id)
    end
  end

  def self.down
    remove_index :hybridizations, :microarray_id
    remove_column :hybridizations, :microarray_id
  end
end
