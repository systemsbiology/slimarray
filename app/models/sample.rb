class Sample < ActiveRecord::Base
  require 'spreadsheet/excel'
  require 'parseexcel'
  require 'csv'
  include Spreadsheet
  
  belongs_to :microarray

  belongs_to :organism
  belongs_to :starting_quality_trace, :class_name => "QualityTrace", :foreign_key => "starting_quality_trace_id"
  belongs_to :amplified_quality_trace, :class_name => "QualityTrace", :foreign_key => "amplified_quality_trace_id"
  belongs_to :fragmented_quality_trace, :class_name => "QualityTrace", :foreign_key => "fragmented_quality_trace_id"
  belongs_to :microarray
  belongs_to :label
  
  has_many :sample_terms, :dependent => :destroy
  has_many :sample_texts, :dependent => :destroy

  has_many :sample_list_samples
  has_many :sample_lists, :through => :sample_list_samples

  validates_presence_of :sample_name, :short_sample_name
  validates_length_of :sample_name, :maximum => 100
  validates_length_of :short_sample_name, :maximum => 50

  attr_accessor :naming_element_selections, :naming_element_visibility,
    :text_values, :schemed_name
  
  def name_with_label
    label ? "#{sample_name} (#{label.name})" : sample_name
  end

  def schemed_name=(attributes)
    naming_scheme = microarray.chip.sample_set.naming_scheme

    # clear out old naming scheme records
    sample_terms.each {|t| t.destroy}
    sample_texts.each {|t| t.destroy}

    # create the new records
    self.sample_terms = terms_for(attributes)
    self.sample_texts = texts_for(attributes)
    self.sample_name = naming_scheme.generate_sample_description(attributes)[0..58]
    self.sample_group_name = naming_scheme.generate_sample_group_name(attributes)
  end
  
  def naming_element_visibility
    naming_scheme = microarray.chip.sample_set.naming_scheme

    if(naming_scheme != nil)
      return @naming_element_visibility || naming_scheme.visibilities_from_terms(sample_terms)
    else
      return nil
    end
  end
  
  def text_values
    naming_scheme = microarray.chip.sample_set.naming_scheme

    if(naming_scheme != nil)
      return @text_values || naming_scheme.texts_from_terms(sample_texts)
    else
      return nil
    end
  end
  
  def naming_element_selections
    naming_scheme = microarray.chip.sample_set.naming_scheme

    if(naming_scheme != nil)
      return @naming_element_selections || naming_scheme.element_selections_from_terms(sample_terms)
    else
      return nil
    end
  end  
  
  def validate
    #TODO: decide how to handle duplication
    ## make sure date/short_sample_name/sample_name combo is unique
    #submission_date = microarray.chip.sample_set.submission_date

    #s = Sample.find(
    #  :all, :include => {:microarray => {:chip => :sample_set}},
    #  :conditions => ["sample_sets.submission_date = ? AND short_sample_name = ? AND sample_name = ?",
    #    submission_date, short_sample_name, sample_name]
    #)
    #if( s != nil && s.id != id )
    #  errors.add("Duplicate submission date/short_sample_name/sample_name")
    #end
    
    # remove problem characters
    self.sample_name.gsub!(/(\ |\+|\&|\#|\(|\)|\/|\\)/, '')

    # look for all the things that are problematic for making a filename:
    # * non-existent sample name
    # * spaces
    # * characters other than underscores and dashes
    if sample_name == nil
      errors.add("Sample name must be supplied")
    elsif sample_name[/\ /] != nil ||
        sample_name[/\+/] != nil ||
        sample_name[/\&/] != nil ||
        sample_name[/\#/] != nil ||
        sample_name[/\(/] != nil ||
        sample_name[/\)/] != nil ||
        sample_name[/\//] != nil ||
        sample_name[/\\/] != nil
      errors.add("Sample name must contain only letters, numbers, underscores and dashes or it")
    end
  end
  
  def self.to_csv(naming_scheme = "")
    ###########################################
    # set up spreadsheet
    ###########################################
    
    csv_file_name = "#{RAILS_ROOT}/tmp/csv/samples_" +
      "#{Date.today.to_s}-#{naming_scheme}.csv"
    
    csv_file = File.open(csv_file_name, 'wb')
    CSV::Writer.generate(csv_file) do |csv|
      if(naming_scheme == "")
        csv << [ "Raw Data Path",
          "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Sample Group Name",
          "Chip Type",
          "Chip Name",
          "Chip Number",
          "Array Number",
          "Organism",
          "Submitted By",
          "Project",
          "Naming Scheme"
        ]

        samples = Sample.find( :all, :conditions => "sample_sets.naming_scheme_id IS NULL",
          :include => [:organism, {:microarray => {:chip => {:sample_set => [:project, :chip_type]}}}], :order => "samples.sample_name ASC" )

        for sample in samples
          if(sample.microarray != nil)
            microarray = sample.microarray
            chip = microarray.chip
            sample_set = chip.sample_set

            chip_name = chip.name
            chip_number = chip.chip_number
            array_number = microarray.array_number
            raw_data_path = microarray.raw_data_path
          else
            chip_name = chip_number = array_number = raw_data_path = ""
          end
          csv << [ raw_data_path,
            sample.id,
            sample_set.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.sample_group_name,
            sample_set.chip_type.name,
            chip_name,
            chip_number,
            array_number,
            sample.organism.name,
            sample_set.submitted_by,
            sample_set.project.name,
            "None"
          ]
        end
      else
        scheme = NamingScheme.find(:first, :conditions => { :name => naming_scheme })
        
        if(scheme.nil?)
          return nil
        end
        
        # stock headings
        headings = [ "Raw Data Path",
          "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Sample Group Name",
          "Chip Type",
          "Chip Name",
          "Chip Number",
          "Array Number",
          "Organism",
          "Submitted By",
          "Project",
          "Naming Scheme"
        ]

        # headings for naming elements
        naming_elements = 
          scheme.naming_elements.find(:all, :order => "element_order ASC")
        naming_elements.each do |e|
          headings << e.name
        end

        csv << headings

        samples = Sample.find( :all, :conditions => ["sample_sets.naming_scheme_id = ?", scheme.id],
          :include => [:organism, {:microarray => {:chip => {:sample_set => [:project, :chip_type]}}}], :order => "samples.sample_name ASC" )

        current_row = 0
        for sample in samples
          microarray = sample.microarray
          if(microarray != nil)
            chip = microarray.chip
            sample_set = chip.sample_set

            chip_name = chip.name
            chip_number = chip.chip_number
            array_number = microarray.array_number
            raw_data_path = microarray.raw_data_path
          else
            chip_name = chip_number = array_number = raw_data_path = ""
          end
          column_values = [ raw_data_path,
            sample.id,
            sample_set.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.sample_group_name,
            sample_set.chip_type.name,
            chip_name,
            chip_number,
            array_number,
            sample.organism.name,
            sample_set.submitted_by,
            sample_set.project.name,
            scheme.name
          ]
          # values for naming elements
          naming_elements.each do |e|
            value = ""
            if(e.free_text == true)
              sample_text = SampleText.find(:first, 
                :conditions => {:sample_id => sample.id,
                  :naming_element_id => e.id})
              if(sample_text != nil)
                value = sample_text.text
              end
            else
              sample_term = SampleTerm.find(:first,
                :include => :naming_term,
                :conditions => ["sample_id = ? AND naming_terms.naming_element_id = ?",
                  sample.id, e.id] )
              if(sample_term != nil)
                value = sample_term.naming_term.term
              end
            end
            column_values << value
          end

          csv << column_values
        end
      end    
    end
  
    csv_file.close
     
    return csv_file_name
  end

#  def self.from_csv(csv_file_name, scheme_generation_allowed = false)
#
#    row_number = 0
#    header_row = nil
#
#    transaction do
#      CSV.open(csv_file_name, 'r') do |row|
#        # grab the header row or process sample rows
#        if(row_number == 0)
#          header_row = row
#        else
#          begin
#            sample = Sample.find(row[1].to_i)
#            sample_set = sample.microarray.chip.sample_set
#          rescue
#            sample_set = SampleSet.new
#            sample = Sample.new(:microarray => Microarray.new(:chip => Chip.new(:sample_set => sample_set)))
#          end
#        
#          # check to see if this sample should have a naming scheme
#          if(row[13] == "None")
#            ###########################################
#            # non-naming schemed sample
#            ###########################################
#          
#            # there should be 13 cells in each row
#            if(row.size != 14)
#              return "Wrong number of columns in row #{row_number}. Expected 14"
#            end
#
#            if( !sample.new_record? )
#              sample.destroy_existing_naming_scheme_info
#            end
#          
#            errors = sample.update_unschemed_columns(row)
#            if(errors != "")
#              return errors + " in row #{row_number} of non-naming schemed samples"
#            end
#          else
#            ###########################################
#            # naming schemed samples
#            ###########################################
#
#            naming_scheme = NamingScheme.find(:first, 
#              :conditions => {:name => row[13]})
#            # make sure this sample has a naming scheme
#            if(naming_scheme.nil?)
#              if(scheme_generation_allowed)
#                naming_scheme = NamingScheme.create(:name => row[13])
#              else
#                return "Naming scheme #{row[13]} doesn't exist in row #{row_number}"
#              end
#            end
#
#            naming_elements =
#              naming_scheme.naming_elements.find(:all, :order => "element_order ASC")
#
#            expected_columns = 14 + naming_elements.size
#            if(row.size > expected_columns)
#              # create new naming elements if that's allowed
#              # otherwise return an error message
#              if(scheme_generation_allowed)
#                if(naming_elements.size > 0)
#                  current_element_order = naming_elements[-1].element_order + 1
#                else
#                  current_element_order = 1
#                end
#                (14..header_row.size-1).each do |i|
#                  NamingElement.create(
#                    :name => header_row[i],
#                    :element_order => current_element_order,
#                    :group_element => true,
#                    :optional => true,
#                    :naming_scheme_id => naming_scheme.id,
#                    :free_text => false,
#                    :include_in_sample_description => true,
#                    :dependent_element_id => 0)
#                  current_element_order += 1
#                end
#                
#                # re-populate naming elements array
#                naming_elements =
#                  naming_scheme.naming_elements.find(:all, :order => "element_order ASC")
#              else
#                return "Wrong number of columns in row #{row_number}. " +
#                  "Expected #{expected_columns}"
#              end
#            end
#
#            if( !sample.new_record? )
#              sample.destroy_existing_naming_scheme_info
#            end
#          
#            # update the sample attributes
#            errors = sample.update_unschemed_columns(row)
#            if(errors != "")
#              return errors + " in row #{row_number}"
#            end
#
#            # create the new naming scheme records
#            current_column_index = 14
#            naming_elements.each do |e|
#              # do nothing if there's nothing in the cell
#              if(row[current_column_index] != nil)
#                if(e.free_text == true)
#                  sample_text = SampleText.new(
#                    :sample_id => sample.id,
#                    :naming_element_id => e.id,
#                    :text => row[current_column_index]
#                  )
#                  if(!sample_text.save)
#                    return "Unable to create #{e.name} for row #{row_number}"
#                  end
#                else
#                  naming_term = NamingTerm.find(:first, 
#                    :conditions => ["naming_element_id = ? AND " +
#                      "(term = ? OR abbreviated_term = ?)",
#                      e.id,
#                      row[current_column_index],
#                      row[current_column_index] ])
#                  # if naming term wasn't found,
#                  # match leading 0's if there are any
#                  if(naming_term.nil?)
#                    naming_term = NamingTerm.find(:first, 
#                      :conditions => ["naming_element_id = ? AND " +
#                        "(term REGEXP ? OR abbreviated_term REGEXP ?)",
#                        e.id,
#                        "0*" + row[current_column_index],
#                        "0*" + row[current_column_index] ])
#                  end
#                  if(naming_term.nil?)
#                    if(scheme_generation_allowed)
#                      naming_term = NamingTerm.create!(
#                        :naming_element_id => e.id,
#                        :term => row[current_column_index],
#                        :abbreviated_term => row[current_column_index],
#                        :term_order => 0
#                      )
#                    else
#                      return "Naming term #{row[current_column_index]} doesn't " +
#                        "exist for #{e.name} for row #{row_number}"
#                    end
#                  end
#                  sample_term = SampleTerm.new(
#                    :sample_id => sample.id,
#                    :naming_term_id => naming_term.id
#                  )
#                  if(!sample_term.save)
#                    return "Unable to create #{e.name} for row #{row_number}"
#                  end
#                end
#              end
#              current_column_index += 1
#            end
#            sample_set.update_attributes(:naming_scheme_id => naming_scheme.id)
#          end
#        end      
#        row_number += 1
#      end
#    end
#
#    return ""
#  end

  def destroy_existing_naming_scheme_info
    SampleText.find(:all, 
      :conditions => {:sample_id => id}
    ). each do |st|
      st.destroy
    end
    SampleTerm.find(:all, 
      :conditions => {:sample_id => id}
    ). each do |st|
      st.destroy
    end
  end

  def update_unschemed_columns(row)
    chip_type = ChipType.find(:first, 
      :conditions => [ "name = ? OR short_name = ?", row[6], row[6] ])
    if(chip_type.nil?)
      return "Chip type doesn't exist"
    end
    
    organism = Organism.find(:first, :conditions => { :name => row[10] })
    if(organism.nil?)
      organism = Organism.create(:name => row[10])
    end
    
    project = Project.find(:first, :conditions => { :name => row[12] })
    if(project.nil?)
      return "Project doesn't exist"
    end

    chip = microarray.chip
    sample_set = chip.sample_set

    unless(
        update_attributes(
          :short_sample_name => row[3],
          :sample_name => row[4],
          :sample_group_name => row[5],
          :organism_id => organism.id
        ) &&
        sample_set.update_attributes(
          :submission_date => row[2],
          :chip_type_id => chip_type.id,
          :submitted_by => row[11],
          :project_id => project.id
        )
      )

      return "Problem updating values for sample id=#{id}: #{errors.full_messages}"
    end

    if(raw_data_path)
      microarray.update_attributes(:raw_data_path => row[0])
    elsif(row[0] && row[7] && row[9])
      chip_name = row[7]
      chip_number = row[8]

      chip.update_attributes(:name => chip_name)
      microarray.update_attributes(:array_number => row[9])
    end
    
    return ""
  end
  
  def raw_data_path
    microarray.raw_data_path
  end
  
  def file_root
    if(raw_data_path != nil && raw_data_path.match(/^.*\/(.*?)\.\w{3}$/))
      return raw_data_path.match(/^.*\/(.*?)\.\w{3}$/)[1]
    else
      return ""
    end
  end
  
  def summary_hash
    return {
      :id => id,
      :file_root => file_root,
      :sample_description => sample_name,
      :submission_date => submission_date,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/samples/#{id}"
    }
  end
  
  def detail_hash
    sample_term_array = Array.new
    sample_terms.each do |st|
      sample_term_array << {
        st.naming_term.naming_element.name => st.naming_term.term
      }
    end
    
    sample_text_array = Array.new
    sample_texts.each do |st|
      sample_text_array << {
        st.naming_element.name => st.text
      }
    end
    
    return {
      :id => id,
      :user => sbeams_user,
      :project => project.name,
      :name_on_tube => short_sample_name,
      :sample_description => sample_name,
      :sample_group_name => sample_group_name,
      :submission_date => submission_date,
      :updated_at => updated_at,
      :status => status,
      :naming_scheme => naming_scheme ? naming_scheme.name : "",
      :sample_terms => sample_term_array,
      :sample_texts => sample_text_array,
      :raw_data_path => raw_data_path,
      :raw_data_type => chip_type.platform.raw_data_type || "",
      :file_root => file_root,
      :organism => organism ? organism.name : "",
      :chip_type => chip_type.short_name,
      :chip_type_uri => "#{SiteConfig.site_url}/chip_types/#{chip_type_id}",
      :label => label ? label.name : ""
    }
  end

  def self.find_selected(selected_samples, available_samples)
    samples = Array.new

    if selected_samples != nil
      for sample in available_samples
        if selected_samples[sample.id.to_s] == '1'
          samples << Sample.find(sample.id)
        end
      end
    end

    return samples
  end

  def self.accessible_to_user(user, age_limit = nil)
    cutoff_date = age_limit ? Date.today - age_limit.to_i : 0

    samples = Sample.find(:all, 
      :include => {:microarray => {:chip => {:sample_set => :project}}},
      :conditions => [ "projects.lab_group_id IN (?) AND samples.updated_at > ?",
        user.get_lab_group_ids, cutoff_date ],
      :order => "submission_date DESC, samples.id ASC")
  end

  def self.browse_by(samples, categories, search_prefix = "")
    return nil if categories.nil?

    category = categories.shift

    value = Array.new
    case category
    when "project"
      Project.find(:all).each do |project|
        project_samples = project.samples
        sub_samples = samples & project_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "project_id=#{project.id}")

        value << branch_hash(project.name, sub_samples, sub_prefix, categories)
      end
    when "submission_date"
      SampleSet.all.group_by(&:submission_date).each do |submission_date, sample_sets|
        submission_date_samples = Sample.find(:all, :include => {:microarray => :chip },
          :conditions => ["chips.sample_set_id IN (?)", sample_sets.collect{|s| s.id}])
        sub_samples = samples & submission_date_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "submission_date=#{submission_date}")

        value << branch_hash(submission_date, sub_samples, sub_prefix, categories)
      end
    when "chip_type"
      ChipType.all.each do |chip_type|
        chip_type_samples = chip_type.samples
        sub_samples = samples & chip_type_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "chip_type_id=#{chip_type.id}")

        value << branch_hash(chip_type.name, sub_samples, sub_prefix, categories)
      end
    when "organism"
      Organism.find(:all).each do |organism|
        organism_samples = organism.samples
        sub_samples = samples & organism_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "organism_id=#{organism.id}")

        value << branch_hash(organism.name, sub_samples, sub_prefix, categories)
      end
    when "status"
      ["submitted", "hybridized"].each do |status|
        status_samples = Sample.find(:all, :include => {:microarray => {:chip => :sample_set}},
          :conditions => ["sample_sets.status = ?", status])
        sub_samples = samples & status_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "status=#{status}")

        value << branch_hash(status, sub_samples, sub_prefix, categories)
      end
    when "naming_scheme"
      NamingScheme.all.each do |naming_scheme|
        scheme_samples = Sample.find(:all, :include => {:microarray => {:chip => :sample_set}},
          :conditions => ["sample_sets.naming_scheme_id = ?", naming_scheme.id])
        sub_samples = samples & scheme_samples

        next if sub_samples.size == 0

        if(naming_scheme.nil?)
          sub_prefix = combine_search(search_prefix, 'naming_scheme_id=')
          value << branch_hash("None", sub_samples, sub_prefix, categories)
        else
          sub_prefix = combine_search(search_prefix, "naming_scheme_id=#{naming_scheme.id}")
          value << branch_hash(naming_scheme.name, sub_samples, sub_prefix, categories)
        end
      end
    when "lab_group"
      LabGroup.find(:all).each do |lab_group|
        lab_group_samples = Array.new
        Project.for_lab_group(lab_group).each do |project|
          lab_group_samples.concat(project.samples)
        end
        sub_samples = samples & lab_group_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "lab_group_id=#{lab_group.id}")

        value << branch_hash(lab_group.name, sub_samples, sub_prefix, categories)
      end
    when /naming_element-(\d+)/
      element = NamingElement.find($1)
      
      element.naming_terms.each do |term|
        samples_for_term = Sample.find(:all, :include => :sample_terms,
                                       :conditions => ["sample_terms.naming_term_id = ?", term.id])
        sub_samples = samples & samples_for_term
        sub_prefix = combine_search(search_prefix, "naming_term_id=#{term.id}")
        
        next if sub_samples.size == 0

        value << branch_hash(term.term, sub_samples, sub_prefix, categories)
      end
    else
      value = nil
    end

    return value
  end

  def self.find_by_sanitized_conditions(conditions)
    accepted_keys = {
      'project_id' => 'sample_sets.project_id',
      'submission_date' => 'sample_sets.submission_date',
      'chip_type_id' => 'sample_sets.chip_type_id',
      'organism_id' => 'chip_types.organism_id',
      'naming_scheme_id' => 'sample_sets.naming_scheme_id',
      'naming_term_id' => 'sample_terms.naming_term_id',
      'lab_group_id' => 'projects.lab_group_id',
    }

    sanitized_conditions = Array.new

    conditions.each do |key, value|
      if accepted_keys.include?(key)
        value.to_s.split(/,/).each do |subvalue|
          sanitized_conditions << {accepted_keys[key] => subvalue}
        end
      end
    end

    samples = Array.new

    sanitized_conditions.each do |condition|
      search_samples = Sample.find(
        :all,
        :include => [:sample_terms, {:microarray => {:chip => {:sample_set => [:chip_type, :project]}}}],
        :conditions => condition
      )

      if(samples.size > 0)
        samples = samples & search_samples
      else
        samples = search_samples
      end
    end

    return samples
  end

  def self.browsing_categories
    categories = [
      ['Lab Group', 'lab_group'],
      ['Naming Scheme', 'naming_scheme'],
      ['Organism', 'organism'],
      ['Project', 'project'],
      ['Chip Type', 'chip_type'],
      ['Submission Date', 'submission_date'],
    ]

    NamingScheme.find(:all, :order => "name ASC").each do |scheme|
      scheme.naming_elements.find(:all, :order => "element_order ASC").each do |element|
        categories << ["#{scheme.name}: #{element.name}", "naming_element-#{element.id}"]
      end
    end

    return categories
  end

  def self.combine_search(base_string, added_string)
    added_string.match(/\A(.*?)=(.*?)\Z/)
    key = $1
    value = $2

    if(base_string.length == 0)
      return added_string
    elsif( base_string.match(/#{key}=(\d+)/) )
      return base_string.gsub(/#{key}=(\d+)/, "#{key}=#{$1},#{value}")
    else
      return "#{base_string}&#{added_string}"
    end
  end

  def self.branch_hash(name, samples, prefix, categories)
    return {
      :name => name,
      :number => samples.size,
      :search_string => prefix,
      :children => Sample.browse_by(samples, categories.dup, prefix)
    }
  end

  def short_and_long_name
    "#{short_sample_name} (#{sample_name})"
  end
  
  def short_and_long_name_with_label
    "#{short_sample_name}:#{sample_name} (#{label && label.name})"
  end

  def terms_for(schemed_params)
    naming_scheme = microarray.chip.sample_set.naming_scheme

    terms = Array.new
    
    count = 1
    for element in naming_scheme.ordered_naming_elements
      depends_upon_element_with_no_selection = false
      depends_upon_element = element.depends_upon_element
      if(depends_upon_element != nil && schemed_params[depends_upon_element.safe_name].to_i <= 0)
        depends_upon_element_with_no_selection = true
      end
      
      # the element must:
      # 1) not be a free text element
      # 2) have a selection
      # 3) not be dependent on an element with no selection
      if( !element.free_text &&
          schemed_params[element.safe_name].to_i > 0 &&
          !depends_upon_element_with_no_selection )
        terms << SampleTerm.new( :sample_id => id, :term_order => count,
          :naming_term_id => NamingTerm.find(schemed_params[element.safe_name]).id )
        count += 1
      end
    end
    
    return terms
  end

  def texts_for(schemed_params)
    naming_scheme = microarray.chip.sample_set.naming_scheme

    texts = Array.new
    
    for element in naming_scheme.ordered_naming_elements
      depends_upon_element_with_no_selection = false
      depends_upon_element = element.depends_upon_element
      if(depends_upon_element != nil && schemed_params[depends_upon_element.safe_name].to_i <= 0)
        depends_upon_element_with_no_selection = true
      end
      
      # the element must:
      # 1) be a free text element
      # 3) not be dependent on an element with no selection
      if( element.free_text &&
          !depends_upon_element_with_no_selection )
        texts << SampleText.new( :sample_id => id, :naming_element_id => element.id,
          :text => schemed_params[element.safe_name] )
      end
    end
    
    return texts
  end
end
