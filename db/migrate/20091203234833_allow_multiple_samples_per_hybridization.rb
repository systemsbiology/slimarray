class AllowMultipleSamplesPerHybridization < ActiveRecord::Migration

  class OldHybridization < ActiveRecord::Base
    set_table_name "hybridizations"

    belongs_to :sample
  end

  class NewHybridization < ActiveRecord::Base
    set_table_name "hybridizations"

    has_many :samples
  end

  class OldSample < ActiveRecord::Base
    set_table_name "samples"

    has_one :hybridization
  end

  class NewSample < ActiveRecord::Base
    set_table_name "samples"

    belongs_to :hybridization
  end

  def self.up
    add_column :samples, :hybridization_id, :integer
    add_index :samples, :hybridization_id

    OldHybridization.all.each do |h|
      s = NewSample.find(h.sample_id)
      s.update_attributes(:hybridization_id => h.id)
    end

    remove_index :hybridizations, :sample_id
    remove_column :hybridizations, :sample_id
  end

  def self.down
    puts "This migration can't be safely reversed"
    raise ActiveRecord::IrreversibleMigration
  end
end
