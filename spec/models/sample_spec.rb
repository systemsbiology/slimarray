require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'parseexcel'

describe "Sample" do
  fixtures :all

  it "should load a csv of sample info without a naming scheme" do
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
  
  it "should load a csv of sample info with a naming scheme" do
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

  it "should load a csv of updated unschemed samples" do
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/updated_unschemed_samples.csv"
  
    errors = Sample.from_csv(csv_file)

    errors.should == ""
    
    # one change was made to sample 1
    sample_1 = Sample.find( samples(:sample1).id )
    sample_1.short_sample_name.should == "yng1"
    
    # multiple changes to sample 2
    sample_2 = Sample.find( samples(:sample2).id )
    sample_2.short_sample_name.should == "old1"
    sample_2.sample_name.should == "Old1"
    sample_2.chip_type_id.should == chip_types(:mouse).id
    sample_2.sbeams_user.should == "robert"
    sample_2.project_id.should == projects(:another).id
    sample_2.organism.name.should == "Hyena"
  end
  
  it "from csv updated schemed samples" do
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/updated_yeast_scheme_samples.csv"
    
    errors = Sample.from_csv(csv_file)
    
    errors.should == ""
    
    # changes to schemed sample
    SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample6).id,
      :naming_term_id => naming_terms(:mutant).id } ).should_not == nil
    SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample6).id,
      :naming_term_id => naming_terms(:replicateA).id } ).should_not == nil
    sample_6_number = SampleText.find(:first, :conditions => {
      :sample_id => samples(:sample6).id,
      :naming_element_id => naming_elements(:subject_number).id } )
    sample_6_number.text.should == "32236"
    assert_equal naming_schemes(:yeast_scheme).id,
      Sample.find( samples(:sample6) ).naming_scheme.id
  end
  
  it "should load a csv of sample info going from no scheme to scheme" do
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/no_scheme_to_scheme.csv"

    errors = Sample.from_csv(csv_file)

    errors.should == ""
    
    # changes to schemed sample
    SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => naming_terms(:wild_type).id } ).should_not == nil
    SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => naming_terms(:heat).id } ).should_not == nil
    SampleTerm.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_term_id => naming_terms(:replicateB).id } ).should_not == nil
    sample_6_number = SampleText.find(:first, :conditions => {
      :sample_id => samples(:sample3).id,
      :naming_element_id => naming_elements(:subject_number).id } )
    sample_6_number.text.should == "234"
    assert_equal naming_schemes(:yeast_scheme).id,
      Sample.find( samples(:sample3).id ).naming_scheme_id
  end

  it "should load a csv of sample info with a new naming scheme" do
    csv_file = "#{RAILS_ROOT}/test/fixtures/csv/update_samples_new_scheme.csv"

    errors = Sample.from_csv(csv_file, true)

    errors.should == ""
    
    # new naming scheme
    scheme = NamingScheme.find(:first, :conditions => {:name => "Badger"})
    scheme.should_not == nil
    
    # naming elements
    age_elements = NamingElement.find(:all,
      :conditions => { :name => "Age", :element_order => 1, :group_element => true,
        :optional => true, :naming_scheme_id => scheme.id, :free_text => false,
        :include_in_sample_description => true
      }
    )
    age_elements.size.should == 1
    age_element = age_elements[0]
    
    disposition_elements = NamingElement.find(:all,
      :conditions => { :name => "Disposition", :element_order => 2, :group_element => true,
        :optional => true, :naming_scheme_id => scheme.id, :free_text => false,
        :include_in_sample_description => true
      }
    )
    disposition_elements.size.should == 1
    disposition_element = disposition_elements[0]
    
    # naming terms
    age_1_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "1", :abbreviated_term => "1", :naming_element_id => age_element.id,
        :term_order => 0
      }
    )
    age_1_terms.size.should == 1
    age_2_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "2", :abbreviated_term => "2", :naming_element_id => age_element.id,
        :term_order => 0
      }
    )
    age_2_terms.size.should == 1
    age_3_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "3", :abbreviated_term => "3", :naming_element_id => age_element.id,
        :term_order => 0
      }
    )
    age_3_terms.size.should == 1
    age_3_term = age_3_terms[0]

    feisty_disposition_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "Feisty", :abbreviated_term => "Feisty", :naming_element_id => disposition_element.id,
        :term_order => 0
      }
    )
    feisty_disposition_terms.size.should == 1
    feisty_disposition_term = feisty_disposition_terms[0]
    mellow_disposition_terms = NamingTerm.find(:all,
      :conditions => {
        :term => "Mellow", :abbreviated_term => "Mellow", :naming_element_id => disposition_element.id,
        :term_order => 0
      }
    )
    mellow_disposition_terms.size.should == 1

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
      row.at(column).to_s.should == cell
      column += 1
    end
  end

  it "should take sample selections and provide the corresponding samples" do
    sample_1 = create_sample
    sample_2 = create_sample
    sample_3 = create_sample
    available_samples = [sample_1, sample_2, sample_3]

    selections = Hash.new
    selections[sample_1.id.to_s] = '1'
    selections[sample_3.id.to_s] = '1'

    Sample.find_selected(selections, available_samples).should == [sample_1, sample_3]
  end

  it "should provide all samples available to hybridize with no excluded hybridizations" do
    Sample.available_to_hybridize.should == [ samples(:sample6), samples(:sample5),
      samples(:sample1), samples(:sample3) ]
  end

  it "should provide all samples available to hybridize excluding any given hybridizations" do
    hybridization_1 = new_hybridization(:sample => samples(:sample3))
    hybridization_2 = new_hybridization(:sample => samples(:sample5))
    excluded_hybridizations = [hybridization_1, hybridization_2]

    Sample.available_to_hybridize(excluded_hybridizations).
      should == [ samples(:sample6), samples(:sample1) ]
  end
end
