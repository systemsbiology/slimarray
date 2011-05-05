class NamingScheme < ActiveRecord::Base
  require 'csv'

  extend ApiAccessible
  
  has_many :naming_elements, :dependent => :destroy
  has_many :sample_sets, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name

  def destroy_warning
    sample_sets = SampleSet.find(:all, :conditions => ["naming_scheme_id = ?", id])
    naming_elements = NamingElement.find(:all, :conditions => ["naming_scheme_id = ?", id])
    
    return "Destroying this naming scheme will also destroy:\n" + 
           sample_sets.size.to_s + " sample set(s)\n" +
           naming_elements.size.to_s + " naming element(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def ordered_naming_elements
    return NamingElement.find(:all, :conditions => { :naming_scheme_id => id },
                                            :order => "element_order ASC" )
  end
  
  def default_visibilities
    visibility = Array.new

    for element in ordered_naming_elements
      if( element.dependent_element_id != nil && element.dependent_element_id > 0 )
        visibility << false
      else
        visibility << true
      end
    end
    
    return visibility
  end
  
  def default_texts
    text_values = Hash.new

    for element in ordered_naming_elements
      # free text
      if( element.free_text )
        text_values[element.name] = ""
      end
    end
    
    return text_values
  end

  def visibilities_from_params(schemed_params)
    visibility = Array.new
    
    for element in ordered_naming_elements
      if( schemed_params[element.safe_name] == nil )
        visibility << false
      else
        visibility << true
      end
    end
    
    return visibility
  end
  
  def texts_from_params(schemed_params)
    text_values = Hash.new

    for element in ordered_naming_elements
      # free text
      if( element.free_text )
        if(schemed_params[element.safe_name] == nil)
          text_values[element.name] = ""
        else
          text_values[element.name] = schemed_params[element.safe_name]
        end
      end
    end
    
    return text_values
  end

  def element_selections_from_params(schemed_params)
    selections = Array.new
    
    for n in 0..ordered_naming_elements.size-1
      element = ordered_naming_elements[n]
      if( !element.free_text )
        if( schemed_params[element.safe_name] == nil )
          selections[n] = nil
        else
          selections[n] = schemed_params[element.safe_name]
        end
      end
    end
    
    return selections
  end
  
  def generate_sample_description(schemed_params)
    name = ""
    
    for element in ordered_naming_elements
      depends_upon_element_with_no_selection = false
      depends_upon_element = element.depends_upon_element
      if(depends_upon_element != nil && schemed_params[depends_upon_element.safe_name].to_i <= 0)
        depends_upon_element_with_no_selection = true
      end

      # put an underscore between terms
      if(name.length > 0)
        name += "_"
      end

      if( schemed_params[element.safe_name] != nil && !depends_upon_element_with_no_selection )
        # free text
        if( element.free_text )
          name += schemed_params[element.safe_name]
        elsif( schemed_params[element.safe_name].to_i > 0 &&
               NamingTerm.find(schemed_params[element.safe_name]).abbreviated_term != nil )
          name += NamingTerm.find(schemed_params[element.safe_name]).abbreviated_term
        end
      end
    end
    
    return name
  end
  
  def generate_sample_group_name(schemed_params)
    name = ""
    
    for element in ordered_naming_elements
      next unless element.group_element

      depends_upon_element_with_no_selection = false
      depends_upon_element = element.depends_upon_element
      if(depends_upon_element != nil && schemed_params[depends_upon_element.safe_name].to_i <= 0)
        depends_upon_element_with_no_selection = true
      end

      # put an underscore between terms
      if(name.length > 0)
        name += "_"
      end

      if( schemed_params[element.safe_name] != nil && !depends_upon_element_with_no_selection )
        # free text
        if( element.free_text )
          name += schemed_params[element.safe_name]
        elsif( schemed_params[element.safe_name].to_i > 0 &&
               NamingTerm.find(schemed_params[element.safe_name]).abbreviated_term != nil )
          name += NamingTerm.find(schemed_params[element.safe_name]).abbreviated_term
        end
      end
    end
    
    return name
  end
  
  def visibilities_from_terms(sample_terms)
    # get default visibilities
    visibility = default_visibilities
    
    # modify visibilities based on actual selections
    for term in sample_terms
      # see if there's a naming term for this element,
      # and if so show it
      i = ordered_naming_elements.index( term.naming_term.naming_element )
      if( i != nil)
        visibility[i] = true
      end        
    end

    # find dependent elements, and show them
    # if the element they depend upon is shown
    for i in (0..ordered_naming_elements.size-1)
      element = ordered_naming_elements[i]

      # does this element depend upon another?
      if( element.dependent_element_id != nil && element.dependent_element_id > 0 )
        dependent_element = NamingElement.find(element.dependent_element_id)
        # check each term to see if the dependent is used
        for term in sample_terms
          if(term.naming_term.naming_element == dependent_element)
            visibility[i] = true
          end
        end
      end
    end
    
    return visibility
  end
  
  def texts_from_terms(sample_texts)
    text_values = Hash.new
    # set sample texts
    for text in sample_texts
      text_values[text.naming_element.name] = text.text
    end
    
    return text_values
  end
  
  def element_selections_from_terms(sample_terms)
    selections = Array.new(ordered_naming_elements.size, -1)
    
    for term in sample_terms
      # see if there's a naming term for this element,
      # and if so record selection
      naming_term = term.naming_term
      i = ordered_naming_elements.index( naming_term.naming_element )
      if( i != nil)
        selections[i] = naming_term.id
      end
    end
    
    return selections
  end
  
  def summary_hash(with = nil)
    hash = {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/naming_schemes/#{id}"
    }

    if(with)
      with.split(",").each do |key|
        key = key.to_sym

        if NamingScheme.api_methods.include? key
          hash[key] = self.send(key)
        end
      end
    end

    return hash
  end
  
  def detail_hash
    naming_element_array = Array.new
    naming_elements.find(:all, :order => "element_order ASC").each do |ne|
      naming_term_array = Array.new
      ne.naming_terms.find(:all, :order => "term_order ASC").each do |nt|
        naming_term_array << nt.term
      end
      
      naming_element_array << {
        :name => ne.name,
        :group_element => ne.group_element,
        :optional => ne.optional,
        :free_text => ne.free_text,
        :depends_on => ne.depends_upon_element ? ne.depends_upon_element.name : "",
        :naming_terms => naming_term_array
      }
    end
    
    return {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :naming_elements => naming_element_array
    }
  end
  
  def to_csv
    csv_file_name = "#{RAILS_ROOT}/tmp/csv/#{SiteConfig.site_name}_naming_scheme_" +
      "#{name}-#{Date.today.to_s}.csv"
    
    csv_file = File.open(csv_file_name, 'wb')
    CSV::Writer.generate(csv_file) do |csv|
      naming_elements.sort{|x,y| x.element_order <=> y.element_order }.each do |element|
        csv << ["Naming Element", element.name]
        csv << ["Order", element.element_order]
        csv << ["Group Element", to_yes_or_no(element.group_element)]
        csv << ["Optional", to_yes_or_no(element.optional)]
        csv << ["Free Text", to_yes_or_no(element.free_text)]
        csv << ["Depends On", element.depends_upon_name]
        csv << ["Include in Sample Description",
          to_yes_or_no(element.include_in_sample_description)]
        
        if(element.free_text == false)
          csv << ["Naming Terms"]
          csv << ["Term","Abbreviated Term","Order"]

          element.naming_terms.sort{|x,y| x.term_order <=> y.term_order }.each do |term|
            csv << [term.term, term.abbreviated_term, term.term_order]
          end
        end

        csv << [""]
      end
    end
    
    csv_file.close
  end

  def self.from_csv(scheme_name, csv_file_name)
    # complain if there's already a naming scheme by this name
    existing_scheme = NamingScheme.find(:first, :conditions => {:name => scheme_name})
    if existing_scheme != nil
      puts "There's already a naming scheme named #{existing_scheme.name}"
      return nil
    end


    naming_scheme = NamingScheme.create(:name => scheme_name)

    csv = CSV.open(csv_file_name, 'r')

    naming_element = NamingElement.new
    in_naming_terms = false
    csv.each do |row|
      if(in_naming_terms)
        if(row.size == 3)
          NamingTerm.create!(
            :naming_element => naming_element,
            :term => row[0],
            :abbreviated_term => row[1],
            :term_order => row[2]
          )
        else
          in_naming_terms = false
        end
      else
        case row[0]
        when "Naming Element"
          naming_element = NamingElement.new(
            :naming_scheme => naming_scheme,
            :name => row[1]
          )
        when "Order"
          naming_element.element_order = row[1].to_i
        when "Group Element"
          naming_element.group_element = from_yes_or_no(row[1])
        when "Optional"
          naming_element.optional = from_yes_or_no(row[1])
        when "Free Text"
          naming_element.free_text = from_yes_or_no(row[1])
        when "Depends On"
          depends_upon_element = NamingElement.find(:first,
            :conditions => {:naming_scheme_id => naming_scheme.id, :name => row[1]})
          if(depends_upon_element.nil?)
            naming_element.dependent_element_id = nil
          else
            naming_element.dependent_element_id = depends_upon_element.id
          end
        when "Include in Sample Description"
          naming_element.include_in_sample_description = from_yes_or_no(row[1])
        when "Term"
          in_naming_terms = true
          naming_element.save!
        when nil
          naming_element.save!
        end
      end
    end
    naming_element.save!

    return naming_scheme
  end

  api_reader :project_ids
  def project_ids
    projects = Project.find(:all, :include => :sample_sets, :conditions => {"sample_sets.naming_scheme_id" => id})

    return projects.collect {|p| p.id}
  end

  def self.populated_for_user(user)
    all_schemes = NamingScheme.find(:all, :order => "name ASC")

    lab_group_ids = user.get_lab_group_ids

    populated_schemes = all_schemes.select do |scheme|
      SampleSet.find(:all, :include => :project,
        :conditions => ["naming_scheme_id = ? AND projects.lab_group_id IN (?)", scheme.id, lab_group_ids]).size > 0
    end

    return populated_schemes
  end

  private

  def to_yes_or_no(bool)
    bool ? "Yes" : "No"
  end

  # If it's not yes, then it's no
  def self.from_yes_or_no(text)
    if(text =~ /yes/i)
      return true
    else
      return false
    end
  end

end
