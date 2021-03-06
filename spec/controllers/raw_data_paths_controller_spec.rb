require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RawDataPathsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff
  end

  describe "POST 'create'" do
    it "should be successful with a valid chip name, array number and path" do
      @microarray = mock_model(Microarray)
      Microarray.should_receive(:find).with(
        :first,
        :include => :chip,
        :conditions => [ "chips.name = ? AND microarrays.array_number = ?",
                         "251485010001", "2" ]
      ).and_return(@microarray)
      @microarray.should_receive(:update_attributes).with(:raw_data_path => "/path/to/data.txt")

      post :create, :chip_name => "251485010001", :array_number => 2, :path => "/path/to/data.txt"
      response.should be_success
    end

    it "should not be successful when no matching microarray is found" do
      Microarray.should_receive(:find).with(
        :first,
        :include => :chip,
        :conditions => [ "chips.name = ? AND microarrays.array_number = ?",
                         "251485010001", "2" ]
      ).and_return(nil)

      post :create, :chip_name => "251485010001", :array_number => 2, :path => "/path/to/data.txt"
      response.should_not be_success
    end

  end
end
