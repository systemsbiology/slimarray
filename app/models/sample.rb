class Sample < ActiveRecord::Base
  require 'spreadsheet/excel'
  require 'parseexcel'
  require 'csv'
  include Spreadsheet
  
  has_one :hybridization, :dependent => :destroy

  belongs_to :chip_type
  belongs_to :project
  belongs_to :organism
  belongs_to :starting_quality_trace, :class_name => "QualityTrace", :foreign_key => "starting_quality_trace_id"
  belongs_to :amplified_quality_trace, :class_name => "QualityTrace", :foreign_key => "amplified_quality_trace_id"
  belongs_to :fragmented_quality_trace, :class_name => "QualityTrace", :foreign_key => "fragmented_quality_trace_id"
  belongs_to :naming_scheme
  
  has_many :sample_terms, :dependent => :destroy
  has_many :sample_texts, :dependent => :destroy
  
  validates_associated :chip_type, :project
  validates_presence_of :sample_name, :short_sample_name, :submission_date,
                        :project_id, :sample_group_name
  validates_length_of :short_sample_name, :maximum => 50
  validates_length_of :sample_name, :maximum => 59
  validates_length_of :sbeams_user, :maximum => 20
  validates_length_of :status, :maximum => 50

  attr_accessor :naming_element_selections, :naming_element_visibility,
    :text_values, :schemed_name
  
  def validate
    # make sure date/short_sample_name/sample_name combo is unique
    s = Sample.find_by_submission_date_and_short_sample_name_and_sample_name(
        submission_date, short_sample_name, sample_name)
    if( s != nil && s.id != id )
      errors.add("Duplicate submission date/short_sample_name/sample_name")
    end
    
    # look for all the things that infuriate GCOS or SBEAMS:
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
        csv << [ "CEL File",
          "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Sample Group Name",
          "Chip Type",
          "Organism",
          "SBEAMS User",
          "Project",
          "Naming Scheme"
        ]

        samples = Sample.find( :all, :conditions => {:naming_scheme_id => nil},
          :include => [:project, :chip_type, :organism], :order => "samples.id ASC" )

        for sample in samples
          if(sample.hybridization != nil)
            cel_file = sample.hybridization.raw_data_path
          else
            cel_file = ""
          end
          csv << [ cel_file,
            sample.id,
            sample.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.sample_group_name,
            sample.chip_type.name,
            sample.organism.name,
            sample.sbeams_user,
            sample.project.name,
            "None"
          ]
        end
      else
        scheme = NamingScheme.find(:first, :conditions => { :name => naming_scheme })
        
        if(scheme.nil?)
          return nil
        end
        
        # stock headings
        headings = [ "CEL File",
          "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Sample Group Name",
          "Chip Type",
          "Organism",
          "SBEAMS User",
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

        samples = Sample.find( :all, 
          :conditions => {:naming_scheme_id => scheme.id},
          :include => [:project, :chip_type, :organism],
          :order => "samples.id ASC" )

        current_row = 0
        for sample in samples
          if(sample.hybridization != nil)
            cel_file = sample.hybridization.raw_data_path
          else
            cel_file = ""
          end
          column_values = [ cel_file,
            sample.id,
            sample.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.sample_group_name,
            sample.chip_type.name,
            sample.organism.name,
            sample.sbeams_user,
            sample.project.name,
            sample.naming_scheme.name
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

  def self.from_csv(csv_file_name, scheme_generation_allowed = false)

    row_number = 0
    header_row = nil

    CSV.open(csv_file_name, 'r') do |row|
      # grab the header row or process sample rows
      if(row_number == 0)
        header_row = row
      else
        begin
          sample = Sample.find(row[1].to_i)
        rescue
          sample = Sample.new
        end
      
        # check to see if this sample should have a naming scheme
        if(row[10] == "None")
          ###########################################
          # non-naming schemed sample
          ###########################################
        
          # there should be 10 cells in each row
          if(row.size != 11)
            return "Wrong number of columns in row #{row_number}. Expected 11"
          end

          if( !sample.new_record? )
            sample.destroy_existing_naming_scheme_info
          end
        
          errors = sample.update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number} of non-naming schemed samples"
          end
        else
          ###########################################
          # naming schemed samples
          ###########################################

          naming_scheme = NamingScheme.find(:first, 
            :conditions => {:name => row[10]})
          # make sure this sample has a naming scheme
          if(naming_scheme.nil?)
            if(scheme_generation_allowed)
              naming_scheme = NamingScheme.create(:name => row[10])
            else
              return "Naming scheme #{row[10]} doesn't exist in row #{row_number}"
            end
          end

          naming_elements =
            naming_scheme.naming_elements.find(:all, :order => "element_order ASC")

          expected_columns = 11 + naming_elements.size
          if(row.size > expected_columns)
            # create new naming elements if that's allowed
            # otherwise return an error message
            if(scheme_generation_allowed)
              if(naming_elements.size > 0)
                current_element_order = naming_elements[-1].element_order + 1
              else
                current_element_order = 1
              end
              (11..header_row.size-1).each do |i|
                NamingElement.create(
                  :name => header_row[i],
                  :element_order => current_element_order,
                  :group_element => true,
                  :optional => true,
                  :naming_scheme_id => naming_scheme.id,
                  :free_text => false,
                  :include_in_sample_name => true,
                  :dependent_element_id => 0)
                current_element_order += 1
              end
              
              # re-populate naming elements array
              naming_elements =
                naming_scheme.naming_elements.find(:all, :order => "element_order ASC")
            else
              return "Wrong number of columns in row #{row_number}. " +
                "Expected #{expected_columns}"
            end
          end

          if( !sample.new_record? )
            sample.destroy_existing_naming_scheme_info
          end
        
          # update the sample attributes
          errors = sample.update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number}"
          end

          # create the new naming scheme records
          current_column_index = 11
          naming_elements.each do |e|
            # do nothing if there's nothing in the cell
            if(row[current_column_index] != nil)
              if(e.free_text == true)
                sample_text = SampleText.new(
                  :sample_id => sample.id,
                  :naming_element_id => e.id,
                  :text => row[current_column_index]
                )
                if(!sample_text.save)
                  return "Unable to create #{e.name} for row #{row_number}"
                end
              else
                naming_term = NamingTerm.find(:first, 
                  :conditions => ["naming_element_id = ? AND " +
                    "(term = ? OR abbreviated_term = ?)",
                    e.id,
                    row[current_column_index],
                    row[current_column_index] ])
                # if naming term wasn't found,
                # match leading 0's if there are any
                if(naming_term.nil?)
                  naming_term = NamingTerm.find(:first, 
                    :conditions => ["naming_element_id = ? AND " +
                      "(term REGEXP ? OR abbreviated_term REGEXP ?)",
                      e.id,
                      "0*" + row[current_column_index],
                      "0*" + row[current_column_index] ])
                end
                if(naming_term.nil?)
                  if(scheme_generation_allowed)
                    naming_term = NamingTerm.create(
                      :naming_element_id => e.id,
                      :term => row[current_column_index],
                      :abbreviated_term => row[current_column_index],
                      :term_order => 0
                    )
                  else
                    return "Naming term #{row[current_column_index]} doesn't " +
                      "exist for #{e.name} for row #{row_number}"
                  end
                end
                sample_term = SampleTerm.new(
                  :sample_id => sample.id,
                  :naming_term_id => naming_term.id
                )
                if(!sample_term.save)
                  return "Unable to create #{e.name} for row #{row_number}"
                end
              end
            end
            current_column_index += 1
          end
          sample.update_attributes(:naming_scheme_id => naming_scheme.id)
        end
      end      
      row_number += 1
    end

    return ""
  end

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
    
    organism = Organism.find(:first, :conditions => { :name => row[7] })
    if(organism.nil?)
      organism = Organism.create(:name => row[7])
    end
    
    project = Project.find(:first, :conditions => { :name => row[9] })
    if(project.nil?)
      return "Project doesn't exist"
    end

    if(!update_attributes(
          :submission_date => row[2],
          :short_sample_name => row[3],
          :sample_name => row[4],
          :sample_group_name => row[5],
          :chip_type_id => chip_type.id,
          :organism_id => organism.id,
          :sbeams_user => row[8],
          :project_id => project.id
        ))
      puts errors.full_messages
      return "Problem updating values for sample id=#{id}: #{errors.full_messages}"
    end
    
    return ""
  end
  
  def raw_data_path
    if(hybridization.nil?)
      return nil
    else
      return hybridization.raw_data_path
    end
  end
  
  def file_root
    return raw_data_path.match(/.*\/(.*?)\.\w{3}/)[1]
  end
  
  def summary_hash
    return {
      :id => id,
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
      :submission_date => submission_date,
      :updated_at => updated_at,
      :status => status,
      :naming_scheme => naming_scheme ? naming_scheme.name : "",
      :sample_terms => sample_term_array,
      :sample_texts => sample_text_array,
      :raw_data_path => raw_data_path,
      :file_root => file_root
    }
  end
end
