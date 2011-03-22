class Organism < ActiveRecord::Base
  has_many :chip_types, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name

  def samples
    Sample.find(:all, :include => {:microarray => {:chip => {:sample_set => :chip_type}}},
                :conditions => ["chip_types.organism_id = ?", self.id])
  end
end
