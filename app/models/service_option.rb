class ServiceOption < ActiveRecord::Base
  has_and_belongs_to_many :service_option_sets
  has_many :sample_sets

  def total_cost
    chip_cost + labeling_cost + hybridization_cost + qc_cost + other_cost
  end

  def name_and_price
    "#{name} ($#{total_cost}/sample)"
  end

  def self.usage_between(start_date, end_date)
    samples = Sample.find(:all, :include => {:microarray => {:chip => :sample_set}},
      :conditions => ["chips.hybridization_date >= ? AND chips.hybridization_date <= ? " +
      "AND chips.status = 'hybridized'", start_date, end_date])

    grouped = samples.group_by {|s| s.microarray.chip.sample_set.service_option}
    
    stats = Array.new
    grouped.each do |group, members|
      name = group.try(:name) || "No service option"
      stats << {:name => name, :count => members.size}
    end

    return stats.sort{|a,b| a[:name] <=> b[:name]}
  end
end
