module FixtureReplacement
  attributes_for :bioanalyzer_run do |a|
    
	end

  attributes_for :charge_period do |a|
    
	end

  attributes_for :charge_set do |a|
    
	end

  attributes_for :charge_template do |a|
    
	end

  attributes_for :charge do |a|
    
	end

  attributes_for :chip_transaction do |a|
    a.date = Date.today
    a.lab_group_id = 6
    a.chip_type = default_chip_type
    a.description = String.random
    a.acquired = 0
    a.used = 0
    a.traded_sold = 0
    a.borrowed_in = 0
    a.returned_out = 0
    a.borrowed_out = 0
    a.returned_in = 0
  end

  attributes_for :chip_type do |ct|
    ct.organism = default_organism
    ct.name = String.random(20)
    ct.short_name = String.random(10)
    ct.array_platform = "affy"
    ct.library_package = "Expression"
  end

  attributes_for :hybridization do |h|
    h.sample = default_sample
    h.hybridization_date = Date.today
    h.chip_number = 1
    h.charge_set = default_charge_set
  end

  attributes_for :inventory_check do |a|
    
	end

  attributes_for :lab_membership do |a|
    
	end

  attributes_for :naming_element do |a|
    
	end

  attributes_for :naming_scheme do |a|
    
	end

  attributes_for :naming_term do |a|
    
	end

  attributes_for :organism do |o|
    o.name = String.random
	end

  attributes_for :project do |p|
    p.name = String.random
    p.budget = String.random
    p.active = true
    p.lab_group_id = 1
  end

  attributes_for :quality_trace do |a|
    
	end

  attributes_for :sample_term do |a|
    
	end

  attributes_for :sample_text do |a|
    
	end

  attributes_for :sample do |s|
    s.submission_date = Date.today
    s.short_sample_name = String.random(5)
    s.sample_name = String.random(20)
    s.sample_group_name = String.random(15)
    s.chip_type = default_chip_type
    s.organism = default_organism
    s.sbeams_user = String.random(8)
    s.status = "submitted"
    s.project = default_project
  end

  attributes_for :site_config do |a|
    
	end

  attributes_for :user_profile do |up|
    up.role = "customer"
    up.user_id = 1
  end
end
