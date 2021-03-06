class Charge < ActiveRecord::Base
  belongs_to :charge_set
  belongs_to :microarray

  validates_numericality_of :chips_used
  validates_numericality_of :chip_cost
  validates_numericality_of :labeling_cost
  validates_numericality_of :hybridization_cost
  validates_numericality_of :qc_cost
  validates_numericality_of :other_cost

  # command-line interface to scrape sbeams array request
  def Charge.command_line_sbeams_import
    require("highline")
    
    ui = HighLine.new
    
    username = ui.ask("Username: ")
    password = ui.ask("Password: ") { |q| q.echo = "x" }
    
    request_id = 0
    while(request_id != -1)
      request_id = ui.ask("Array Request ID (-1 to exit): ")
      return if request_id == -1

      # ask what lab group to assign charges into
      lab_groups = LabGroup.find(:all)

      puts "Lab Groups:\n\n"
      for n in 0..lab_groups.size-1
        puts (n+1).to_s + ". " + lab_groups[n].name + "\n"
      end
      lab_group_number = ui.ask("\n> ")
      lab_group_id = lab_groups[lab_group_number.to_i-1].id

      scrape_array_request(username, password, request_id, lab_group_id)
    end
  end

  # web scrape an array_request view form from SBEAMS
  # using scRUBYt!
  def Charge.scrape_array_request(username, password, request_id, lab_group_id)
    require("scrubyt")

    # scraping module generated by scRUBYt! based on a provided example   
    sbeams_data = Scrubyt::Extractor.define do
      fetch(SiteConfig.sbeams_address + 
           "/cgi/Microarray/SubmitArrayRequest.cgi?TABLE_NAME=MA_array_request&array_request_id=" + 
           request_id)
      fill_textfield("username", username)
      fill_textfield("password", password)
      submit(0)
      fill_textarea("comment", "")
      submit(0)
      
      form("/html/body/p/p", { :generalize => true }) do
        table("/form[1]") do
          contact("/table[1]/tr[1]/td[2]")
          project("/table[1]/tr[2]/td[2]")
          slide_type("/table[1]/tr[4]/td[2]")
          samples_per_array("/table[1]/tr[6]/td[2]")
          #hybridization_request("/table[1]/tr[7]/td[2]")
          #scanning_request("/table[1]/tr[8]/td[2]")
          request_date("/table[1]/tr[12]/td[2]")
          row("/p/p/table/tr", { :generalize => true }) do
            slideid("/td[2]")
            sample1("/td[3]/font[1]")
            sample2("/td[6]/font[1]")
          end.ensure_presence_of_pattern("slideid")
        end.ensure_presence_of_pattern("slide_index")
      end
    end

    hash = sbeams_data.to_hash
    
    # project/charge info
    project = hash[0]['project']
    project_elements = project.scan(/\A(.*)\ \[(.*)\]/)

    # get rid of enclosing array
    project_elements = project_elements[0]

    # ensure that there project field is encoded how we expect
    if( project_elements.size != 2 || project_elements[0] == nil )
      raise "Couldn't parse the project field"
    end
    
    project_name = project_elements[0]
    project_budget = project_elements[1]    

    # get slide cost
    slide_type = hash[0]['slide_type']
    array_cost = slide_type.scan(/.*\(\ \$(\d+)\ \)/)
    array_cost = array_cost[0][0]

    samples_per_array = hash[0]['samples_per_array'].to_i

    request_date = hash[0]['request_date']

    # sample name info
    sample1_list = hash[0]['sample1']
    sample1_array = sample1_list.split(/,/)
    
    if(samples_per_array == 2)
      sample2_list = hash[0]['sample2']
      sample2_array = sample2_list.split(/,/)
    end
    
    # use the most recently created charge set
    charge_period = ChargePeriod.find(:first, :order => "id DESC")
    
    # if no charge periods exist, make a default one
    if( charge_period == nil )
      charge_period = ChargePeriod.new(:name => "Default Charge Period")
      charge_period.save
    end

    charge_set = ChargeSet.find(:first, :conditions => ["name = ? AND lab_group_id = ? AND budget = ? AND charge_period_id = ?",
                                           project_name, lab_group_id, project_budget, charge_period.id])
    # see if new charge set need to be created
    if(charge_set == nil)  
      charge_set = ChargeSet.new(:charge_period_id => charge_period.id,
                                  :name => project_name,
                                  :lab_group_id => lab_group_id,
                                  :budget => project_budget
                                  )
      charge_set.save
    end

    for n in 0..sample1_array.size-1
      description = sample1_array[n]
      if(samples_per_array == 2)
        description += "_v_" + sample2_array[n]
      end
      charge = Charge.new(:charge_set_id => charge_set.id,
                          :date => request_date,
                          :description => description,
                          :chips_used => 1,
                          :chip_cost => array_cost,
                          :labeling_cost => 0,
                          :hybridization_cost => 0,
                          :qc_cost => 0,
                          :other_cost => 0)
      charge.save
    end
  end

  def self.from_template_id(template_id, charge_set)
    template = ChargeTemplate.find(template_id) if template_id != nil
    if( template != nil )
      charge = Charge.new(
        :charge_set => charge_set,
        :description => template.description,
        :chips_used => template.chips_used,
        :chip_cost => template.chip_cost,
        :labeling_cost => template.labeling_cost,
        :hybridization_cost => template.hybridization_cost,
        :qc_cost => template.qc_cost,
        :other_cost => template.other_cost
      )
    else
      charge = Charge.new(
        :charge_set => charge_set,
        :chips_used => 0,
        :chip_cost => 0,
        :labeling_cost => 0,
        :hybridization_cost => 0,
        :qc_cost => 0,
        :other_cost => 0
      )
    end

    return charge
  end

  def service_name
    service_option = microarray.try(:chip).try(:sample_set).try(:service_option)

    if service_option
      "#{service_option.notes} #{service_option.name}"
    else
      ""
    end
  end
end
