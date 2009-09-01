require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Project" do
  fixtures :projects

  it "should provide a string with the name and in parenthesis the budget" do
    project = create_project(:name => "Genetics", :budget => "1234")
    project.name_and_budget.should == "Genetics (1234)"
  end

  describe "providing projects accessible to a user" do
  
    before(:each) do
      @user = mock( "User" )
      @projects = mock("Project list")
      @lab_group_1 = mock("Lab Group")
      @lab_group_2 = mock("Lab Group")
      @lab_groups = [@lab_group_1, @lab_group_2]
      @project_1 = create_project(:name => "Aardvark Project", :lab_group_id => @lab_group_1.id)
      @project_2 = create_project(:name => "Badget Project", :lab_group_id => @lab_group_2.id)
      @lab_1_projects = [@project_1]
      @lab_2_projects = [@project_2]
    end

    describe "with active projects only" do
      it "should provide all projects for admin or staff users" do
        @user.should_receive(:staff_or_admin?).and_return(true)
        Project.should_receive(:find).with(:all, :order => "name ASC").
          and_return(@projects)
        Project.accessible_to_user(@user, true).should == @projects
      end

      it "should provide user-accessible active projects for non-staff or admin users" do
        @user.should_receive(:staff_or_admin?).and_return(false)
        @user.should_receive(:lab_groups).and_return(@lab_groups)
        Project.should_receive(:find).with(
          :all,
          :conditions => { :lab_group_id => @lab_group_1.id, :active => true },
          :order => "name ASC"
        ).and_return( [@project_1] )
        Project.should_receive(:find).with(
          :all,
          :conditions => { :lab_group_id => @lab_group_2.id, :active => true },
          :order => "name ASC"
        ).and_return( [@project_2] )
        Project.accessible_to_user(@user, true).should == [@project_1, @project_2]
      end
    end

    describe "with both active and inactive projects" do
      it "should provide all projects for admin or staff users" do
        @user.should_receive(:staff_or_admin?).and_return(true)
        Project.should_receive(:find).with(:all, :order => "name ASC").
          and_return(@projects)
        Project.accessible_to_user(@user, true).should == @projects
      end

      it "should provide all user-accessible projects for non-staff or admin users" do
        @user.should_receive(:staff_or_admin?).and_return(false)
        @user.should_receive(:lab_groups).and_return(@lab_groups)
        Project.should_receive(:find).with(
          :all,
          :conditions => { :lab_group_id => @lab_group_1.id },
          :order => "name ASC"
        ).and_return( [@project_1] )
        Project.should_receive(:find).with(
          :all,
          :conditions => { :lab_group_id => @lab_group_2.id },
          :order => "name ASC"
        ).and_return( [@project_2] )
        Project.accessible_to_user(@user, false).should == [@project_1, @project_2]
      end
    end
  end

  it "should provide a hash of summary attributes" do
    SiteConfig.should_receive(:site_url).and_return("http://example.com")
    project = create_project(:name => "Fungus Project")

    project.summary_hash.should == {
      :id => project.id,
      :name => "Fungus Project",
      :updated_at => project.updated_at,
      :uri => "http://example.com/projects/#{project.id}"
    }
  end

  it "should provide a hash of detailed attributes" do
    SiteConfig.should_receive(:site_url).exactly(3).times.and_return("http://example.com")
    lab_group = mock("LabGroup", :id => 3, :name => "Fungus Group")

    project = create_project(
      :name => "Fungus Project"
    )
    project.stub!(:lab_group_id).and_return(3)
    project.stub!(:lab_group).and_return(lab_group)

    sample_1 = create_sample(:project => project)
    sample_2 = create_sample(:project => project)

    project.detail_hash.should == {
      :id => project.id,
      :name => "Fungus Project",
      :lab_group => "Fungus Group",
      :lab_group_uri => "http://example.com/lab_groups/#{lab_group.id}",
      :updated_at => project.updated_at,
      :sample_uris => ["http://example.com/samples/#{sample_1.id}",
                        "http://example.com/samples/#{sample_2.id}"]
    }
  end

  it "should provide projects associated with a lab group" do
    lab_group_1 = mock_model(LabGroup)
    lab_group_2 = mock_model(LabGroup)
    project_1 = create_project(:lab_group => lab_group_1)
    project_2 = create_project(:lab_group => lab_group_1)
    project_3 = create_project(:lab_group => lab_group_2)

    Project.for_lab_group(lab_group_1).should == [project_1, project_2]
  end

  it "should provide the name of the associated lab group" do
    project = create_project
    lab_group = mock_model(LabGroup, :name => "Yeast Lab")
    project.stub!(:lab_group_id).and_return(lab_group.id)
    LabGroup.stub!(:all_by_id).and_return({lab_group.id => lab_group})

    project.lab_group_name.should == "Yeast Lab"
  end
end
