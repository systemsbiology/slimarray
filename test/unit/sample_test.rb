require File.dirname(__FILE__) + '/../test_helper'
require 'parseexcel'

class SampleTest < Test::Unit::TestCase
  fixtures :all

  def test_to_csv_unschemed
    csv_file_name = Sample.to_csv
    
    csv = CSV.open(csv_file_name, 'r')
    
    # heading
    assert_row_equal([
      "CEL File",
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
    ], csv.shift)
    
    # samples
    assert_row_equal([
      "",
      samples(:sample1).id.to_s,
      "2006-02-10",
      "yng",
      "Young",
      "Young",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "None"
    ], csv.shift)
    
    assert_row_equal([
      "/tmp/20060210_01_Old.CEL",
      samples(:sample2).id.to_s,
      "2006-02-10",
      "old",
      "Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "None"
    ], csv.shift)
    
    assert_row_equal([
      "",
      samples(:sample3).id.to_s,
      "2006-02-10",
      "vold",
      "Very Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "None"
    ], csv.shift)
    
    assert_row_equal([
      "/tmp/20060210_02_Very Very Old.CEL",
      samples(:sample4).id.to_s,
      "2006-02-10",
      "vvold",
      "Very Very Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "None"
    ], csv.shift)
    
    assert_row_equal([
      "",
      samples(:sample5).id.to_s,
      "2006-09-10",
      "bb",
      "Bob B",
      "Bob",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "Bob's Stuff",
      "None"
    ], csv.shift)
  end
  
  def test_to_csv_schemed
    csv_file_name = Sample.to_csv('Yeast Scheme')
    
    csv = CSV.open(csv_file_name, 'r')
    
    assert_row_equal([
      "CEL File",
      "Sample ID",
      "Submission Date",
      "Short Sample Name",
      "Sample Name",
      "Sample Group Name",
      "Chip Type",
      "Organism",
      "SBEAMS User",
      "Project",
      "Naming Scheme",
      "Strain",
      "Perturbation",
      "Perturbation Time",
      "Replicate",
      "Subject Number",
    ], csv.shift)
    
    assert_row_equal([
      "",
      samples(:sample6).id.to_s,
      "2007-05-31",
      "a1",
      "wt_HT_024_B_32234",
      "wt_HT_024",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "Bob's Stuff",
      "Yeast Scheme",
      "wild-type",
      "heat",
      "024",
      "B",
      "32234"      
    ], csv.shift)
  end

  def test_from_csv_updated_unschemed_samples
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/updated_unschemed_samples.csv"
  
    errors = Sample.from_csv(csv_file)

    assert_equal "", errors
    
    # one change was made to sample 1
    sample_1 = Sample.find( samples(:sample1).id )
    assert_equal "yng1", sample_1.short_sample_name
    
    # multiple changes to sample 2
    sample_2 = Sample.find( samples(:sample2).id )
    assert_equal "old1", sample_2.short_sample_name
    assert_equal "Old1", sample_2.sample_name
    assert_equal chip_types(:mouse).id, sample_2.chip_type_id
    assert_equal "robert", sample_2.sbeams_user
    assert_equal projects(:another).id, sample_2.project_id
    assert_equal "Hyena", sample_2.organism.name
  end
  
  def test_from_csv_updated_schemed_samples
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/updated_yeast_scheme_samples.csv"
    
    errors = Sample.from_csv(csv_file)
    
    assert_equal "", errors
    
    # changes to schemed sample
    assert_not_nil SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample6).id,
      :naming_term_id => naming_terms(:mutant).id } )
    assert_not_nil SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample6).id,
      :naming_term_id => naming_terms(:replicateA).id } )
    sample_6_number = SampleText.find(:first, :conditions => {
      :sample_id => samples(:sample6).id,
      :naming_element_id => naming_elements(:subject_number).id } )
    assert_equal "32236", sample_6_number.text
    assert_equal naming_schemes(:yeast_scheme).id,
      Sample.find( samples(:sample6) ).naming_scheme.id
  end
  
  def test_from_csv_no_scheme_to_scheme
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/no_scheme_to_scheme.csv"

    errors = Sample.from_csv(csv_file)

    assert_equal "", errors
    
    # changes to schemed sample
    assert_not_nil SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => naming_terms(:wild_type).id } )
    assert_not_nil SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => naming_terms(:heat).id } )
    assert_not_nil SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => naming_terms(:replicateB).id } )
    sample_6_number = SampleText.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_element_id => naming_elements(:subject_number).id } )
    assert_equal "234", sample_6_number.text
    assert_equal naming_schemes(:yeast_scheme).id,
      Sample.find( samples(:sample3).id ).naming_scheme_id
  end

  def test_from_csv_new_naming_scheme
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/update_samples_new_scheme.csv"

    errors = Sample.from_csv(csv_file, true)

    assert_equal "", errors
    
    # new naming scheme
    scheme = NamingScheme.find(:first, :conditions => {:name => "Badger"})
    assert_not_nil scheme
    
    # naming elements
    age_elements = NamingElement.find(:all,
      :conditions => { :name => "Age", :element_order => 1, :group_element => true,
        :optional => true, :naming_scheme_id => scheme.id, :free_text => false,
        :include_in_sample_name => true
      }
    )
    assert_equal 1, age_elements.size
    age_element = age_elements[0]
    
    disposition_elements = NamingElement.find(:all,
      :conditions => { :name => "Disposition", :element_order => 2, :group_element => true,
        :optional => true, :naming_scheme_id => scheme.id, :free_text => false,
        :include_in_sample_name => true
      }
    )
    assert_equal 1, disposition_elements.size
    disposition_element = disposition_elements[0]
    
    # naming terms
    age_1_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "1", :abbreviated_term => "1", :naming_element_id => age_element.id,
        :term_order => 0
      }
    )
    assert_equal 1, age_1_terms.size
    age_2_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "2", :abbreviated_term => "2", :naming_element_id => age_element.id,
        :term_order => 0
      }
    )
    assert_equal 1, age_2_terms.size
    age_3_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "3", :abbreviated_term => "3", :naming_element_id => age_element.id,
        :term_order => 0
      }
    )
    assert_equal 1, age_3_terms.size
    age_3_term = age_3_terms[0]

    feisty_disposition_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "Feisty", :abbreviated_term => "Feisty", :naming_element_id => disposition_element.id,
        :term_order => 0
      }
    )
    assert_equal 1, feisty_disposition_terms.size
    feisty_disposition_term = feisty_disposition_terms[0]
    mellow_disposition_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "Mellow", :abbreviated_term => "Mellow", :naming_element_id => disposition_element.id,
        :term_order => 0
      }
    )
    assert_equal 1, mellow_disposition_terms.size

    # sample terms and scheme
    assert_equal 1, SampleTerm.find(:all, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => age_3_term.id } ).size
    assert_equal 1, SampleTerm.find(:all, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => feisty_disposition_term.id } ).size
    assert_equal scheme.id,
      Sample.find( samples(:sample3).id ).naming_scheme_id
  end
  
  def assert_row_equal(expected, row)
    column = 0
    expected.each do |cell|
      assert_equal cell, row.at(column).to_s
      column += 1
    end
  end
end
