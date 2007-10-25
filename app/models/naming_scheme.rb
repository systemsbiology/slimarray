class NamingScheme < ActiveRecord::Base
  has_many :naming_elements, :dependent => :destroy
  has_many :samples, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name

  def destroy_warning
    samples = Sample.find(:all, :conditions => ["naming_scheme_id = ?", id])
    naming_elements = NamingElement.find(:all, :conditions => ["naming_scheme_id = ?", id])
    
    return "Destroying this naming scheme will also destroy:\n" + 
           samples.size.to_s + " sample(s)\n" +
           naming_elements.size.to_s + " naming element(s)\n" +
           "Are you sure you want to destroy it?"
  end
end