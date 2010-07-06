require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Microarray do
  it "should have a name" do
    label_b = create_label(:name => "b")
    label_a = create_label(:name => "a")
    sample_1 = create_sample(:sample_name => "Time_0", :label => label_a)
    sample_2 = create_sample(:sample_name => "Time_60", :label => label_b)
    microarray = create_microarray
    hybridization = create_hybridization(:samples => [sample_2, sample_1], :microarray => microarray)

    microarray.name.should == "Time_0_v_Time_60"
  end

  describe "doing a custom find" do
    before(:each) do
      @lab_group = mock_model(LabGroup)
      @user = mock_model(User)
      @project = create_project(:lab_group_id => @lab_group.id)
      @naming_scheme = create_naming_scheme
      @sample = create_sample(:project => @project, :naming_scheme => @naming_scheme)
      @microarray = create_microarray
      @hybridization = create_hybridization(:samples => [@sample], :microarray => @microarray)

      @user.should_receive(:get_lab_group_ids).and_return( [@lab_group.id] )
    end

    it "should provide all accessible microarrays without any custom fields" do
      Microarray.custom_find(@user, {}).should == [@microarray]
    end

    it "should provide only the samples matching a particular project id and naming_scheme" do
      # a microarray that shouldn't show up in the find
      create_microarray

      Microarray.custom_find(@user, {:project_id => @project.id, :naming_scheme_id => @naming_scheme.id}).should == [@microarray]
    end
  end

  it "should provide a summary hash" do
    naming_scheme = create_naming_scheme
    project = create_project
    sample = create_sample(:sample_name => "1_hour", :naming_scheme => naming_scheme, :project => project)
    chip = create_chip(:name => "251486827605")
    microarray = create_microarray(:array_number => 2, :chip => chip)
    hybridization = create_hybridization(:samples => [sample], :microarray => microarray)

    microarray.summary_hash("scheme,project,chip_name,schemed_descriptors,raw_data_path,array_number").should == {
      :name => "1_hour",
      :scheme => naming_scheme.id,
      :project => project.id,
      :chip_name => "251486827605",
      :schemed_descriptors => [],
      :raw_data_path => hybridization.raw_data_path,
      :array_number => 2,
      :id => microarray.id,
      :updated_at => microarray.updated_at,
      :uri => "#{SiteConfig.site_url}/microarrays/#{microarray.id}"
    }
  end
end
