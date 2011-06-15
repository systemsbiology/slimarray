require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'parseexcel'

describe "Sample" do
  fixtures :all

  it "should write a csv of sample info without a naming scheme" do
    csv_file_name = Sample.to_csv
    
    csv = CSV.open(csv_file_name, 'r')
    
    # heading
    assert_row_equal([
      "Raw Data Path",
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
    ], csv.shift)
    
    # samples
    assert_row_equal([
      "",
      samples(:sample5).id.to_s,
      "2006-09-10",
      "bb",
      "Bob B",
      "Bob",
      "Alligator 670 2.0",
      "chip 5",
      "",
      "1",
      "Mouse",
      "bob",
      "Bob's Stuff",
      "None"
    ], csv.shift)
    
    assert_row_equal([
      "/tmp/20060210_02_Very Very Old.CEL",
      samples(:sample2).id.to_s,
      "2006-02-10",
      "old",
      "Old",
      "Old",
      "Alligator 670 2.0",
      "chip 2",
      "",
      "1",
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
      "chip 3",
      "",
      "1",
      "Mouse",
      "bob",
      "MouseGroup",
      "None"
    ], csv.shift)
    
    assert_row_equal([
      "",
      samples(:sample4).id.to_s,
      "2006-02-10",
      "vvold",
      "Very Very Old",
      "Old",
      "Alligator 670 2.0",
      "chip 4",
      "",
      "1",
      "Mouse",
      "bob",
      "MouseGroup",
      "None"
    ], csv.shift)
    
    assert_row_equal([
      "/tmp/20060210_01_Old.CEL",
      samples(:sample1).id.to_s,
      "2006-02-10",
      "yng",
      "Young",
      "Young",
      "Alligator 670 2.0",
      "chip 1",
      "",
      "1",
      "Mouse",
      "bob",
      "MouseGroup",
      "None"
    ], csv.shift)
  end
  
  it "should write a csv of sample info with a naming scheme" do
    csv_file_name = Sample.to_csv('Yeast Scheme')
    
    csv = CSV.open(csv_file_name, 'r')
    
    assert_row_equal([
      "Raw Data Path",
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
      "chip 6",
      "",
      "1",
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
    csv_file = "#{RAILS_ROOT}/spec/fixtures/csv/updated_unschemed_samples.csv"
  
    errors = Sample.from_csv(csv_file)

    errors.should == ""
    
    # one change was made to sample 1
    sample_1 = Sample.find( samples(:sample1).id )
    sample_1.short_sample_name.should == "yng1"
    
    # multiple changes to sample 2
    sample_2 = Sample.find( samples(:sample2).id )
    sample_2.short_sample_name.should == "old1"
    sample_2.sample_name.should == "Old1"
    sample_2.microarray.array_number.should == 1
    sample_2.microarray.chip.name == "Chip 1"
    sample_2.microarray.chip.chip_number == 1
    sample_set_2 = sample_2.microarray.chip.sample_set
    sample_set_2.chip_type_id.should == chip_types(:mouse).id
    sample_set_2.submitted_by.should == "robert"
    sample_2.project_id.should == projects(:another).id
    sample_2.organism.name.should == "Hyena"
  end
  
  it "from csv updated schemed samples" do
    csv_file = "#{RAILS_ROOT}/spec/fixtures/csv/updated_yeast_scheme_samples.csv"
    
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
      Sample.find( samples(:sample6) ).microarray.chip.sample_set.naming_scheme_id
  end
  
  it "should load a csv of sample info going from no scheme to scheme" do
    csv_file = "#{RAILS_ROOT}/spec/fixtures/csv/no_scheme_to_scheme.csv"

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
      Sample.find( samples(:sample3).id ).microarray.chip.sample_set.naming_scheme_id
  end

  it "should load a csv of sample info with a new naming scheme" do
    csv_file = "#{RAILS_ROOT}/spec/fixtures/csv/update_samples_new_scheme.csv"

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
      Sample.find( samples(:sample3).id ).microarray.chip.sample_set.naming_scheme_id
  end
  
  def assert_row_equal(expected, row)
    column = 0
    expected.each do |cell|
      row.at(column).to_s.should == cell
      column += 1
    end
  end

  it "should load a csv of new unschemed samples with hybridizations" do
    csv_file = "#{RAILS_ROOT}/spec/fixtures/csv/new_unschemed_samples.csv"
  
    errors = Sample.from_csv(csv_file)

    errors.should == ""
    
    new_samples = Sample.find(:all, :limit => 2, :order => "id DESC")
    sample_2 = new_samples[0]
    chip_2 = sample_2.microarray.chip
    sample_set_2 = chip_2.sample_set
    sample_1 = new_samples[1]
    chip_1 = sample_1.microarray.chip
    sample_set_1 = chip_1.sample_set

    sample_set_1.submission_date.should == Date.parse("2010-01-12")
    sample_1.short_sample_name.should == "N"
    sample_1.sample_name.should == "normal"
    sample_1.sample_group_name.should == "normal"
    sample_1.organism.name.should == "Mouse"
    sample_set_1.chip_type.name.should == "Mouse 430 2.0"
    sample_set_1.submitted_by.should == "bob"
    sample_1.project.name.should == "MouseGroup"
    chip_1.hybridization_date.should == Date.parse("2010-01-12")
    chip_1.chip_number.should == 1
    sample_1.microarray.raw_data_path.should == "/tmp/20100112_01_normal.CEL"
    sample_1.microarray.should_not be_nil
    sample_1.microarray.array_number.should == 1
    sample_1.microarray.chip.should_not be_nil
    sample_1.microarray.chip.name.should == "20100112_01"

    sample_set_2.submission_date.should == Date.parse("2010-01-12")
    sample_2.short_sample_name.should == "D"
    sample_2.sample_name.should == "diseased"
    sample_2.sample_group_name.should == "diseased"
    sample_2.organism.name.should == "Mouse"
    sample_set_2.chip_type.name.should == "Mouse 430 2.0"
    sample_set_2.submitted_by.should == "bob"
    sample_2.project.name.should == "MouseGroup"
    chip_2.hybridization_date.should == Date.parse("2010-01-12")
    chip_2.chip_number.should == 2
    sample_2.microarray.raw_data_path.should == "/tmp/20100112_02_diseased.CEL"
    sample_2.microarray.should_not be_nil
    sample_2.microarray.array_number.should == 2
    chip_2.should_not be_nil
    chip_2.name.should == "20100112_02"
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

  it "should provide the samples accessible to a user" do
    lab_group_1 = mock_model(LabGroup)
    lab_group_2 = mock_model(LabGroup)
    user = mock_model(User, :get_lab_group_ids => [lab_group_1.id])
    sample_1 = create_sample(
      :project => create_project(:lab_group => lab_group_1),
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    sample_2 = create_sample(
      :project => create_project(:lab_group => lab_group_2),
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    
    Sample.accessible_to_user(user).should == [sample_1]
  end

  it "should provide the samples accessible to a user limited by age" do
    lab_group_1 = mock_model(LabGroup)
    lab_group_2 = mock_model(LabGroup)
    user = mock_model(User, :get_lab_group_ids => [lab_group_1.id])
    sample_1 = create_sample(
      :project => create_project(:lab_group => lab_group_1),
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    sample_2 = create_sample(
      :project => create_project(:lab_group => lab_group_2),
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    sample_3 = create_sample(
      :project => create_project(:lab_group => lab_group_1),
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )

    # manually set the updated_at field for sample_3 to be really old since trying to do
    # this through the model class will automatically set updated_at to be now
    sql = "UPDATE samples SET updated_at='2010-01-28 00:00:00' WHERE id=#{sample_3.id};"
    ActiveRecord::Base.connection.execute(sql)
    
    Sample.accessible_to_user(user, "2").should == [sample_1]
  end

  it "should generate a browsing tree Hash" do
    scheme = create_naming_scheme(:name => "Mouse")
    strain = create_naming_element(:naming_scheme => scheme, :name => "Strain")
    bl6 = create_naming_term(:naming_element => strain, :term => "Bl6")
    mutant = create_naming_term(:naming_element => strain, :term => "Mutant")
    age = create_naming_element(:naming_scheme => scheme, :name => "Age")
    one_week = create_naming_term(:naming_element => age, :term => "One Week")
    two_weeks = create_naming_term(:naming_element => age, :term => "Two Weeks")
    project_1 = create_project(:name => "Prion")
    project_2 = create_project(:name => "Cancer")
    sample_1 = create_sample(
      :project => project_1,
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    sample_2 = create_sample(
      :project => project_1,
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    sample_3 = create_sample(
      :project => project_1,
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    sample_4 = create_sample(
      :project => project_2,
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    create_sample_term(:sample => sample_1, :naming_term => bl6)
    create_sample_term(:sample => sample_2, :naming_term => bl6)
    create_sample_term(:sample => sample_3, :naming_term => mutant)
    create_sample_term(:sample => sample_4, :naming_term => bl6)
    create_sample_term(:sample => sample_1, :naming_term => one_week)
    create_sample_term(:sample => sample_2, :naming_term => one_week)
    create_sample_term(:sample => sample_3, :naming_term => two_weeks)
    create_sample_term(:sample => sample_4, :naming_term => two_weeks)

    Sample.browse_by(
      [sample_1, sample_2, sample_3, sample_4],
      ["project", "naming_element-#{strain.id}", "naming_element-#{age.id}"]
    ).should == [
      {
        :name => "Prion",
        :number => 3,
        :search_string => "project_id=#{project_1.id}",
        :children => [
          {
            :name => "Bl6",
            :number => 2,
            :search_string => "project_id=#{project_1.id}&naming_term_id=#{bl6.id}",
            :children => [
              {
                :name => "One Week",
                :number => 2,
                :search_string => "project_id=#{project_1.id}&naming_term_id=#{bl6.id},#{one_week.id}",
                :children => nil
              }
            ]
          },
          {
            :name => "Mutant",
            :number => 1,
            :search_string => "project_id=#{project_1.id}&naming_term_id=#{mutant.id}",
            :children => [
              {
                :name => "Two Weeks",
                :number => 1,
                :search_string => "project_id=#{project_1.id}&naming_term_id=#{mutant.id},#{two_weeks.id}",
                :children => nil
              }
            ]
          }
        ]
      },
      {
        :name => "Cancer",
        :number => 1,
        :search_string => "project_id=#{project_2.id}",
        :children => [
          {
            :name => "Bl6",
            :number => 1,
            :search_string => "project_id=#{project_2.id}&naming_term_id=#{bl6.id}",
            :children => [
              {
                :name => "Two Weeks",
                :number => 1,
                :search_string => "project_id=#{project_2.id}&naming_term_id=#{bl6.id},#{two_weeks.id}",
                :children => nil
              }
            ]
          }
        ]
      }
    ]
  end

  it "should find by a set of conditions after sanitizing them" do
    scheme = create_naming_scheme(:name => "Mouse")
    strain = create_naming_element(:naming_scheme => scheme, :name => "Strain")
    bl6 = create_naming_term(:naming_element => strain, :term => "Bl6")
    mutant = create_naming_term(:naming_element => strain, :term => "Mutant")
    age = create_naming_element(:naming_scheme => scheme, :name => "Age")
    one_week = create_naming_term(:naming_element => age, :term => "One Week")
    two_weeks = create_naming_term(:naming_element => age, :term => "Two Weeks")
    lab_group_1 = mock_model(LabGroup, :name => "Smith Lab")
    project_1 = create_project(:name => "ChIP-Seq", :lab_group => lab_group_1)
    project_2 = create_project(:name => "RNA-Seq")
    chip_type = create_chip_type
    sample_1 = create_sample(
      :project => project_1, 
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set(
            :naming_scheme_id => scheme.id, :chip_type => chip_type,
            :submission_date => '2009-05-01'
          )
        )
      )
    )
    sample_2 = create_sample(
      :project => project_1, 
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set(
            :submission_date => '2009-05-02'
          )
        )
      )
    )
    sample_3 = create_sample(
      :project => project_1, 
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set(
            :submission_date => '2009-05-01',
            :naming_scheme_id => scheme.id, :chip_type => chip_type
          )
        )
      )
    )
    sample_4 = create_sample(
      :project => project_2,
      :microarray => create_microarray(
        :chip => create_chip(
          :sample_set => create_sample_set
        )
      )
    )
    create_sample_term(:sample => sample_1, :naming_term => bl6)
    create_sample_term(:sample => sample_2, :naming_term => mutant)
    create_sample_term(:sample => sample_3, :naming_term => bl6)
    create_sample_term(:sample => sample_4, :naming_term => bl6)
    create_sample_term(:sample => sample_1, :naming_term => one_week)
    create_sample_term(:sample => sample_2, :naming_term => one_week)
    create_sample_term(:sample => sample_3, :naming_term => two_weeks)
    create_sample_term(:sample => sample_4, :naming_term => two_weeks)

    Sample.find_by_sanitized_conditions(
      "controller" => "this",
      "action" => "that",
      "project_id" => project_1.id,
      "submission_date" => '2009-05-01',
      "chip_type_id" => chip_type.id,
      "organism_id" => chip_type.organism_id,
      "naming_scheme_id" => scheme.id,
      "naming_term_id" => "#{one_week.id},#{bl6.id}",
      "lab_group_id" => lab_group_1.id,
      "bob_id" => 123
    ).should == [sample_1]
  end

  it "should provide sample browsing categories" do
    # make sure there are no other schemes to get in the way
    clear_naming_schemes

    scheme = create_naming_scheme(:name => "Mouse")
    strain = create_naming_element(:naming_scheme => scheme, :name => "Strain")

    Sample.browsing_categories.should == [
      ['Lab Group', 'lab_group'],
      ['Naming Scheme', 'naming_scheme'],
      ['Organism', 'organism'],
      ['Project', 'project'],
      ['Chip Type', 'chip_type'],
      ['Submission Date', 'submission_date'],
      ['Mouse: Strain', "naming_element-#{strain.id}"]
    ]
  end

  describe "getting naming element visibility" do
    fixtures :samples, :naming_schemes, :naming_elements, :naming_terms, :sample_terms,
             :sample_texts
    
    it "should return nil with no naming scheme" do
      samples(:sample5).naming_element_visibility.should == nil
    end
    
    it "should return the correct visibility settings with a naming scheme" do
      expected_visibilities = [true, true, true, true, true]
      samples(:sample6).naming_element_visibility.should == expected_visibilities
    end
  end

  describe "getting naming scheme text values" do
    fixtures :samples, :naming_schemes, :naming_elements, :naming_terms, :sample_terms,
             :sample_texts
    
    it "should return nil with no naming scheme" do
      samples(:sample5).text_values.should == nil
    end
    
    it "should return the correct text values with a naming scheme" do
      expected_texts = {"Subject Number" => "32234"}
      samples(:sample6).text_values.should == expected_texts
    end
  end

  describe "getting naming scheme element selections" do
    fixtures :samples, :naming_schemes, :naming_elements, :naming_terms, :sample_terms,
             :sample_texts
    
    it "should return nil with no naming scheme" do
      samples(:sample5).text_values.should == nil
    end
    
    it "should return the correct selections with a naming scheme" do
      expected_selections = [naming_terms(:wild_type).id, naming_terms(:heat).id,
                             naming_terms(:time024).id, naming_terms(:replicateB).id, -1 ]
      samples(:sample6).naming_element_selections.should == expected_selections
    end
  end
  
  describe "making sample terms from schemed parameters" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide an array of the sample terms" do
      @sample = Sample.new(:microarray => Microarray.new(:chip => Chip.new(:sample_set =>
        SampleSet.new(:naming_scheme_id => naming_schemes(:yeast_scheme).id))))

      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA).id, "PerturbationTime" => naming_terms(:time024).id,
        "SubjectNumber" => "3283"
      }
      
      expected_terms = [
        @sample.sample_terms.build(:term_order => 1, :naming_term_id => naming_terms(:wild_type).id),
        @sample.sample_terms.build(:term_order => 2, :naming_term_id => naming_terms(:heat).id),
        @sample.sample_terms.build(:term_order => 3, :naming_term_id => naming_terms(:time024).id),
        @sample.sample_terms.build(:term_order => 4, :naming_term_id => naming_terms(:replicateA).id)
      ]

      @sample.terms_for(schemed_params).each do |observed_term|
        expected_term = expected_terms.shift
        observed_term.attributes.should == expected_term.attributes
      end
    end
  end

  describe "making sample terms from schemed parameters, with a hidden dependent element" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide an array of the sample terms" do
      @sample = Sample.new(:microarray => Microarray.new(:chip => Chip.new(:sample_set =>
        SampleSet.new(:naming_scheme_id => naming_schemes(:yeast_scheme).id))))
      
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => "-1",
        "Perturbation Time" => naming_terms(:time024).id,
        "Replicate" => naming_terms(:replicateA).id, "Subject Number" => "3283"
      }
      
      expected_terms = [
        @sample.sample_terms.build(:term_order => 1, :naming_term_id => naming_terms(:wild_type).id),
        @sample.sample_terms.build(:term_order => 2, :naming_term_id => naming_terms(:replicateA).id)
      ]

      @sample.terms_for(schemed_params).each do |observed_term|
        expected_term = expected_terms.shift
        observed_term.attributes.should == expected_term.attributes
      end
    end
  end
  
  describe "making sample texts from schemed parameters" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide a hash of the sample texts" do
      @sample = Sample.new(:microarray => Microarray.new(:chip => Chip.new(:sample_set =>
        SampleSet.new(:naming_scheme_id => naming_schemes(:yeast_scheme).id))))
      
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA), "PerturbationTime" => naming_terms(:time024),
        "SubjectNumber" => "3283"
      }
      
      expected_texts = [
        SampleText.new(:sample_id => @sample.id,
                       :naming_element_id => naming_elements(:subject_number).id,
                       :text => "3283"),
      ]

      @sample.texts_for(schemed_params).each do |observed_text|
        expected_text = expected_texts.shift
        observed_text.attributes.should == expected_text.attributes
      end
    end
  end
  
  describe "setting the schemed name attribute for a sample" do
    fixtures :all
    
    def do_set
      @sample = samples(:sample6)
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA).id, "PerturbationTime" => naming_terms(:time024).id,
        "SubjectNumber" => "3283"
      }
      @sample.schemed_name = schemed_params
    end
    
    it "should create the appropriate sample terms" do
      do_set

      expected_attribute_sets = [
        { :term_order => 1, :naming_term_id => naming_terms(:wild_type).id },
        { :term_order => 2, :naming_term_id => naming_terms(:heat).id },
        { :term_order => 3, :naming_term_id => naming_terms(:time024).id },
        { :term_order => 4, :naming_term_id => naming_terms(:replicateA).id }
      ]

      @sample.sample_terms.find(:all, :order => "term_order ASC").each do |term|
        attribute_set = expected_attribute_sets.shift
        attribute_set.each do |key, value|
          term[key].should == value
        end
      end
    end
    
    it "should create the appropriate sample texts" do       
      do_set

      attribute_set = { :naming_element_id => naming_elements(:subject_number).id, :text => "3283" }

      text = @sample.sample_texts.find(:all)[0]
      attribute_set.each do |key, value|
        text[key].should == value
      end
    end
  end

  def clear_naming_schemes
    NamingTerm.destroy_all
    NamingElement.destroy_all
    NamingScheme.destroy_all
  end
end
