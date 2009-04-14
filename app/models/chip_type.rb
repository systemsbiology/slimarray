class ChipType < ActiveRecord::Base
  belongs_to :organism
  has_many :chip_transactions, :dependent => :destroy
  has_many :samples, :dependent => :destroy
  has_many :inventory_checks, :dependent => :destroy
  
  validates_uniqueness_of :name
  validates_uniqueness_of :short_name
  validates_length_of :name, :within => 1..250
  validates_length_of :short_name, :within => 1..100

  def destroy_warning
#    samples = Sample.find(:all, :conditions => ["chip_type_id = ?", id])
#    inventory_checks = InventoryCheck.find(:all, :conditions => ["chip_type_id = ?", id])
#    chip_transactions = ChipTransaction.find(:all, :conditions => ["chip_type_id = ?", id])
#    
#    return "Destroying this chip type will also destroy:\n" + 
#           samples.size.to_s + " sample(s)\n" +
#           inventory_checks.size.to_s + " inventory check(s)\n" +
#           chip_transactions.size.to_s + " chip transaction(s)\n" +
#           "Are you sure you want to destroy it?"
    return ""
  end
  
  def validate_on_create
    if organism_id <= 0
      errors.add("Organism")
    end
  end
end
