require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LabGroupProfile do
  fixtures :site_config

  it "should provide a destroy warning" do
    lab_group_profile = LabGroupProfile.create(:lab_group_id => 3)

    lab_group_profile.destroy_warning.should ==
      "Are you sure you want to destroy this lab group?"
  end

  it "should provide a detail hash of attributes" do
    lab_group_profile = LabGroupProfile.create(
      :lab_group_id => 3
    )

    lab_group_profile.detail_hash.should == {}
  end
end
