require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Microarray do
  fixtures :site_config

  it "should have a name" do
    label_b = create_label(:name => "b")
    label_a = create_label(:name => "a")
    sample_1 = create_sample(:sample_name => "Time_0", :label => label_a)
    sample_2 = create_sample(:sample_name => "Time_60", :label => label_b)
    microarray = create_microarray(:samples => [sample_1, sample_2])

    microarray.name.should == "Time_0_v_Time_60"
  end

  describe "doing a custom find" do
    before(:each) do
      Microarray.destroy_all
      @lab_group = mock_model(LabGroup)
      @user = mock_model(User)
      @project = create_project(:lab_group_id => @lab_group.id)
      @naming_scheme = create_naming_scheme
      @sample_set = create_sample_set(:naming_scheme => @naming_scheme)
      @chip = create_chip(:sample_set => @sample_set)
      @microarray = create_microarray(:chip => @chip)
      @sample = create_sample(:microarray => @microarray, :project => @project)

      @user.should_receive(:get_lab_group_ids).and_return( [@lab_group.id] )
    end

    it "should provide all accessible microarrays without any custom fields" do
      Microarray.custom_find(@user, {}).should == [@microarray]
    end

    it "should provide only the samples matching a particular project id and naming_scheme" do
      # a microarray that shouldn't show up in the find
      create_microarray

      Microarray.custom_find(@user, {"project_id" => @project.id, "naming_scheme_id" => @naming_scheme.id}).should == [@microarray]
    end

    it "should provide only samples with 1 sample" do
      # a microarray that shouldn't show up in the find
      sample_2 = create_sample
      sample_3 = create_sample
      microarray_2 = create_microarray(:samples => [sample_2, sample_3])

      Microarray.custom_find(@user, {"project_id" => @project.id.to_s, "naming_scheme_id" => @naming_scheme.id.to_s,
        "sample_number" => "1"}).should == [@microarray]
    end
  end

  it "should provide a summary hash" do
    naming_scheme = create_naming_scheme
    project = create_project
    sample = create_sample(:project => project, :sample_name => "1_hour")
    sample_set = create_sample_set(:naming_scheme => naming_scheme)
    chip = create_chip(:name => "251486827605", :sample_set => sample_set)
    microarray = create_microarray(:array_number => 2, :chip => chip, :samples => [sample], :raw_data_path => "/path/to/data")

    microarray.summary_hash("scheme,project,chip_name,schemed_descriptors,raw_data_path,array_number").should == {
      :name => "1_hour",
      :scheme => naming_scheme.id,
      :project => project.id,
      :chip_name => "251486827605",
      :schemed_descriptors => {},
      :raw_data_path => "/path/to/data",
      :array_number => 2,
      :id => microarray.id,
      :updated_at => microarray.updated_at,
      :uri => "#{SiteConfig.site_url}/microarrays/#{microarray.id}"
    }
  end

  it "should create an GCOS import file" do
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:gcos_output_path => "#{RAILS_ROOT}")
    @site_config.save
    
    chip = create_chip(:chip_number => 1)
    microarray = create_microarray(:chip => chip)
    microarray.samples << create_sample(:sample_name => "test")
    hybridization_set = HybridizationSet.new(
      "chips" => {
        "0" => {
          "id" => chip.id, "name" => "1234"
        }
      }
    )
    hybridization_set.save
    microarray.reload.create_gcos_import_file

    # make sure gcos file was created, then delete it
    expected_file_path = "#{RAILS_ROOT}/1234.txt"
    File.exists?(expected_file_path).should be_true
    FileUtils.rm(expected_file_path)
  end

  it "should create an Affymetrix GeneChip Commnad Console (AGCC) array (ARR) file" do
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:agcc_output_path => "#{RAILS_ROOT}")
    @site_config.save

    chip = create_chip(:chip_number => 1)
    microarray = create_microarray(:chip => chip)
    microarray.samples << create_sample(:sample_name => "test")
    hybridization_set = HybridizationSet.new(
      "chips" => {
        "0" => {
          "id" => chip.id, "name" => "1234"
        }
      }
    )
    hybridization_set.save
    microarray.reload.create_agcc_array_file

    # make sure gcos file was created, then delete it
    expected_file_path = "#{RAILS_ROOT}/1234.ARR"
    File.exists?(expected_file_path).should be_true
    FileUtils.rm(expected_file_path)
  end

end
