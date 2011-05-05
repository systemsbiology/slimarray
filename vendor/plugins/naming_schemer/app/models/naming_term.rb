class NamingTerm < ActiveRecord::Base
  belongs_to :naming_element

  validates_format_of :abbreviated_term, :with => /\A[a-z0-9_-]+\Z/i,
    :message => "can only contain letters, numbers, underscores and hyphens"

  has_many :sample_terms, :dependent => :destroy

  def after_save
    naming_element.update_attributes(:updated_at => Time.now)
  end

  def after_destroy
    naming_element.update_attributes(:updated_at => Time.now)
  end
  
  def destroy_warning
    sample_terms = SampleTerm.find(:all, :conditions => ["naming_term_id = ?", id])
    
    return "Destroying this naming term will also destroy:\n" + 
           sample_terms.size.to_s + " sample term(s)\n" +
           "Are you sure you want to destroy it?"
  end
  
end
