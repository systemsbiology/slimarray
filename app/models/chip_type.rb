class ChipType < ActiveRecord::Base
  belongs_to :organism
  belongs_to :platform
  belongs_to :service_option_set
  has_many :chip_transactions, :dependent => :destroy
  has_many :samples, :dependent => :destroy
  has_many :inventory_checks, :dependent => :destroy
  
  validates_uniqueness_of :name
  validates_uniqueness_of :short_name
  validates_length_of :name, :within => 1..250
  validates_length_of :short_name, :within => 1..100

  def destroy_warning
    samples = Sample.find(:all, :conditions => ["chip_type_id = ?", id])
    inventory_checks = InventoryCheck.find(:all, :conditions => ["chip_type_id = ?", id])
    chip_transactions = ChipTransaction.find(:all, :conditions => ["chip_type_id = ?", id])
    
    return "Destroying this chip type will also destroy:\n" + 
           samples.size.to_s + " sample(s)\n" +
           inventory_checks.size.to_s + " inventory check(s)\n" +
           chip_transactions.size.to_s + " chip transaction(s)\n" +
           "Are you sure you want to destroy it?"
    #return ""
  end
  
  def validate_on_create
    if organism_id <= 0
      errors.add("Organism")
    end
  end

  def organism_name
    organism && organism.name
  end

  def platform_and_name
    "#{name} (#{platform && platform.name})"
  end

  def name_and_short_name
    "#{name} (#{short_name})"
  end

  def summary_hash
    array_platform = platform && platform.name

    return {
      :id => id,
      :name => name,
      :short_name => short_name,
      :array_platform => array_platform,
      :organism => organism ? organism.name: "",
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/chip_types/#{id}"
    }
  end
  
  def detail_hash
    array_platform = platform && platform.name

    return {
      :id => id,
      :name => name,
      :short_name => short_name,
      :array_platform => array_platform,
      :organism => organism.name,
      :updated_at => updated_at,
    }
  end

  def total_inventory
    total = 0

    chip_transactions.each do |t|
      total = total +
        (t.acquired || 0) -
        (t.used || 0) -
        (t.traded_sold || 0)  +
        (t.borrowed_in || 0) -
        (t.returned_out || 0) -
        (t.borrowed_out || 0) +
        (t.returned_in || 0)
    end

    return total
  end

  def service_options
    (service_option_set && service_option_set.service_options) || Array.new
  end
end
