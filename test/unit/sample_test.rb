require File.dirname(__FILE__) + '/../test_helper'
require 'parseexcel'

class SampleTest < Test::Unit::TestCase
  fixtures :all

  def test_to_csv_unschemed
    csv_file_name = Sample.to_csv
    
    csv = CSV.open(csv_file_name, 'r')
    
    # heading
    assert_row_equal([
      "Sample ID",
      "Submission Date",
      "Short Sample Name",
      "Sample Name",
      "Sample Group Name",
      "Chip Type",
      "Organism",
      "SBEAMS User",
      "Project",
    ], csv.shift)
    
    # samples
    assert_row_equal([
      "1",
      "2006-02-10",
      "yng",
      "Young",
      "Young",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
    ], csv.shift)
    
    assert_row_equal([
      "2",
      "2006-02-10",
      "old",
      "Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
    ], csv.shift)
    
    assert_row_equal([
      "3",
      "2006-02-10",
      "vold",
      "Very Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
    ], csv.shift)
    
    assert_row_equal([
      "4",
      "2006-02-10",
      "vvold",
      "Very Very Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
    ], csv.shift)
    
    assert_row_equal([
      "5",
      "2006-09-10",
      "bb",
      "Bob B",
      "Bob",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "Bob's Stuff",
    ], csv.shift)
  end
  
  def test_to_csv_schemed
    csv_file_name = Sample.to_csv('Yeast Scheme')
    
    csv = CSV.open(csv_file_name, 'r')
    
    assert_row_equal([
      "Sample ID",
      "Submission Date",
      "Short Sample Name",
      "Sample Name",
      "Sample Group Name",
      "Chip Type",
      "Organism",
      "SBEAMS User",
      "Project",
      "Strain",
      "Perturbation",
      "Perturbation Time",
      "Replicate",
      "Subject Number",
    ], csv.shift)
    
    assert_row_equal([
      "6",
      "2007-05-31",
      "a1",
      "wt_HT_024_B_32234",
      "wt_HT_024",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "Bob's Stuff",
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
    sample_1 = Sample.find(1)
    assert_equal "yng1", sample_1.short_sample_name
    
    # multiple changes to sample 2
    sample_2 = Sample.find(2)
    assert_equal "old1", sample_2.short_sample_name
    assert_equal "Old1", sample_2.sample_name
    assert_equal 1, sample_2.chip_type_id
    assert_equal "robert", sample_2.sbeams_user
    assert_equal 2, sample_2.project_id
    assert_equal "Hyena", sample_2.organism.name
  end
  
  def test_from_csv_updated_schemed_samples
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/updated_yeast_scheme_samples.csv"
    
    errors = Sample.from_csv(csv_file, true)
    
    assert_equal "", errors
    
    # changes to schemed sample
    assert_not_nil SampleTerm.find(:first, :conditions => {
      :sample_id => 6,
      :naming_term_id => naming_terms(:mutant).id } )
    assert_not_nil SampleTerm.find(:first, :conditions => {
      :sample_id => 6,
      :naming_term_id => naming_terms(:replicateA).id } )
    sample_6_number = SampleText.find(:first, :conditions => {
      :sample_id => 6,
      :naming_element_id => naming_elements(:subject_number).id } )
    assert_equal "32236", sample_6_number.text
  end
  
  def assert_row_equal(expected, row)
    column = 0
    expected.each do |cell|
      assert_equal cell, row.at(column).to_s
      column += 1
    end
  end
end
