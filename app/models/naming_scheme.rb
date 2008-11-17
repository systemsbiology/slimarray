class NamingScheme < ActiveRecord::Base
  require 'csv'
  
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
  
  def ordered_naming_elements
    return NamingElement.find(:all, :conditions => { :naming_scheme_id => id },
                                            :order => "element_order ASC" )
  end
  
  def to_csv
    csv_file_name = "#{RAILS_ROOT}/tmp/csv/#{SiteConfig.site_name}_naming_scheme_" +
      "#{name}-#{Date.today.to_s}.csv"
    
    csv_file = File.open(csv_file_name, 'wb')
    CSV::Writer.generate(csv_file) do |csv|
      naming_elements.each do |ne|
        if(ne.free_text == true)
          csv << [ne.name, "FREE TEXT"]
        else
          csv << [ne.name] + ne.naming_terms.collect {|nt| nt.term}
        end
      end
    end
    
    csv_file.close
  end
end