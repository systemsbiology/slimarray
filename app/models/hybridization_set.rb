class HybridizationSet
  include Validatable

  attr_accessor :date
  attr_accessor :charge_set_id
  attr_accessor :charge_template_id
  attr_accessor :selected_samples
  attr_accessor :hybridizations

  validates_presence_of :date, :charge_template_id
  validates_numericality_of :charge_template_id

  # initialize accepts an option hash with the following parameters:
  #
  # * <tt>date</tt> - The date of the hybridization(s)
  # * <tt>charge_set_id</tt> - The charge set being used
  # * <tt>charge_template_id</tt> - The charge template to base the charges on
  # * <tt>selected_samples</tt> - A Hash of <sample id> => <selected state>
  def initialize(options = {})
    @date = options[:date] || Date.today
    @charge_set_id = options[:charge_set_id]
    @charge_template_id = options[:charge_template_id]
    @selected_samples = options[:selected_samples]
    @hybridizations = Array.new
  end

  def hybridizations(options = {})
    current_hyb_number = options[:last_hyb_number]
    available_samples = options[:available_samples]

    samples = Array.new
    if selected_samples != nil
      for sample in available_samples
        if selected_samples[sample.id.to_s] == '1'
          samples << Sample.find(sample.id)
        end
      end
    end


    for sample in samples
      project = sample.project
      # does user want charge set(s) created based on projects?
      if(@charge_set_id == "-1")
        # get latest charge period
        charge_period = ChargePeriod.find(:first, :order => "name DESC")

        # if no charge periods exist, make a default one
        if( charge_period == nil )
          charge_period = ChargePeriod.new(:name => "Default Charge Period")
          charge_period.save
        end
        
        charge_set = ChargeSet.find(:first, :conditions => ["name = ? AND lab_group_id = ? AND budget = ? AND charge_period_id = ?",
                                     project.name, project.lab_group_id, project.budget, charge_period.id])

        # see if new charge set need to be created
        if(charge_set == nil)
          charge_set = ChargeSet.new(:charge_period_id => charge_period.id,
                                      :name => project.name,
                                      :lab_group_id => project.lab_group_id,
                                      :budget => project.budget
                                      )
          charge_set.save
        end
        
        @charge_set_id = charge_set.id
      end

      current_hyb_number += 1
      @hybridizations << Hybridization.new(:hybridization_date => date,
            :chip_number => current_hyb_number,
            :charge_set_id => @charge_set_id,
            :charge_template_id => charge_template_id,
            :sample_id => sample.id)
    end

    return @hybridizations
  end

  def number
    @hybridizations.size
  end

end
