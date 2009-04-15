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
      @project_1 = create_project(:name => "Aardvark Project")
      @project_2 = create_project(:name => "Badget Project")
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
        @lab_group_1.should_receive(:projects).and_return(@lab_1_projects)
        @lab_1_projects.should_receive(:find).and_return(@lab_1_projects)
        @lab_group_2.should_receive(:projects).and_return(@lab_2_projects)
        @lab_2_projects.should_receive(:find).and_return(@lab_2_projects)
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
        @lab_group_1.should_receive(:projects).and_return(@lab_1_projects)
        @lab_group_2.should_receive(:projects).and_return(@lab_2_projects)
        Project.accessible_to_user(@user, false).should == [@project_1, @project_2]
      end
    end
  end

end
