module FixtureReplacement
  attributes_for :bioanalyzer_run do |a|
    
	end

  attributes_for :charge_period do |a|
    
	end

  attributes_for :charge_set do |a|
    
	end

  attributes_for :charge_template do |t|
    t.name = String.random
    t.chips_used = 1
    t.description = String.random
    t.chip_cost = 100
    t.labeling_cost = 50
    t.hybridization_cost = 25
    t.qc_cost = 5
    t.other_cost = 10
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
    ct.platform = Platform.find_by_name("Affymetrix") || create_platform(:name => "Affymetrix")
    ct.library_package = "Expression"
  end

  attributes_for :hybridization do |h|
    h.samples = [create_sample]
    h.hybridization_date = Date.today
    h.chip_number = 1
    h.charge_set = default_charge_set
    h.microarray = default_microarray
  end

  attributes_for :inventory_check do |ic|
    ic.date = Date.today
    ic.chip_type = default_chip_type
    ic.number_expected = 10
    ic.number_counted = 10
	end

  attributes_for :lab_membership do |a|
    
	end

  attributes_for :naming_element do |ne|
    ne.naming_scheme = default_naming_scheme
    ne.name = String.random
    ne.group_element = true
    ne.optional = true
    ne.free_text = false
    ne.dependent_element_id = nil
  end

  attributes_for :naming_scheme do |ns|
    ns.name = String.random
  end

  attributes_for :naming_term do |nt|
    nt.naming_element = default_naming_element
    nt.term = String.random
    nt.abbreviated_term = String.random(3)
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

  attributes_for :platform do |p|
    p.name = String.random(10)
    p.default_label = create_label
  end

  attributes_for :label do |l|
    l.name = String.random(10)
  end

  attributes_for :chip do |c|
    c.name = String.random(10)
  end

  attributes_for :microarray do |m|
    m.chip = default_chip
  end

  attributes_for :qc_metric do |m|
    m.name = String.random(10)
  end

  attributes_for :qc_set do |s|
    s.hybridization = default_hybridization
  end

  attributes_for :qc_statistic do |s|
    s.qc_set = default_qc_set
    s.qc_metric = default_qc_metric
  end

  attributes_for :qc_threshold do |t|
    t.platform = default_platform
    t.qc_metric = default_qc_metric
  end

  attributes_for :qc_file do |f|
    f.qc_set = default_qc_set
    f.path = String(20)
  end
end
