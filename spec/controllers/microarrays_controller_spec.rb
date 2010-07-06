require 'spec_helper'

describe MicroarraysController do
  include AuthenticatedSpecHelper

  def mock_microarray(stubs={})
    @mock_microarray ||= mock_model(Microarray, stubs)
  end

  before(:each) do
    login_as_user
  end

  describe "GET index" do
    it "assigns all microarrays as @microarrays" do
      Microarray.should_receive(:custom_find).with(@current_user, {
        "project_id" => "12", "naming_scheme_id" => "23", "action"=>"index", "controller"=>"microarrays"}
      ).and_return( [mock_microarray(:summary_hash => "Summary Hash")] )
      get :index, "project_id" => 12, "naming_scheme_id" => 23
      assigns[:microarrays].should == [mock_microarray]
    end
  end

end
