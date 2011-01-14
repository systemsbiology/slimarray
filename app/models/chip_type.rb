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

  def sample_layout(samples, channels)
    layout = Array.new

    if arrays_per_chip == 1
      # 1 array/slide, 1 channel
      if channels == 1
        layout = [{
          :samples => (1..samples).collect do |s|
            { :title => "Slide/Chip #{s}", :slide => s, :array => 1, :channel => 1 }
          end
        }]
      # 1 array/slide, multiple (usually 2) channels
      else
        slide = 1

        while samples > 0
          # handle cases where there aren't enough samples to fill all channels on the slide
          current_channels = [samples, channels].min

          layout << {
            :title => "Slide/Chip #{slide}",
            :samples => (1..current_channels).collect do |channel|
              { :title => "Channel #{channel}", :slide => slide, :array => 1, :channel => channel }
            end
          }

          samples -= channels
          slide += 1
        end
      end
    else
      # multiple arrays/slide, 1 channel
      if channels == 1
        slide = 1

        while samples > 0
          # handle cases where there aren't enough samples to fill all arrays on the slide
          current_arrays = [samples, arrays_per_chip].min

          layout << {
            :title => "Slide/Chip #{slide}",
            :samples => (1..current_arrays).collect do |array|
              { :title => "Array #{array}", :slide => slide, :array => array, :channel => 1 }
            end
          }

          samples -= arrays_per_chip
          slide += 1
        end
      # multiple arrays/slide, multiple (usually 2) channels
      else
        slide = 1

        while samples > 0
          array = 1

          # handle cases where there aren't enough arrays to fill a slide
          current_arrays = [samples.to_f/channels.ceil, arrays_per_chip].min

          while current_arrays > 0
            # handle cases where there aren't enough samples to fill all channels on the array
            current_channels = [samples, channels].min

            layout << {
              :title => "Slide/Chip #{slide}, Array #{array}",
              :samples => (1..current_channels).collect do |channel|
                { :title => "Channel #{channel}", :slide => slide, :array => array, :channel => channel }
              end
            }

            samples -= channels
            current_arrays -= 1
            array += 1
          end

          slide += 1
        end
      end
    end

    return layout
  end

end
