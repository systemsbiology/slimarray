require 'spec_helper'

describe QcSetsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff
  end

  describe "POST 'create'" do
    it "should be successful if the QC Set saves successfully" do
      qc_set = mock_model(QcSet, :save => true)
      QcSet.should_receive(:new).with(
        :chip_name => "20100526_01", :array_number => "1",
        :file => "/path/to/file", :statistics => {"Saturated Spots" => "0"}
      ).and_return qc_set

      post :create, :chip_name => "20100526_01", :array_number => "1",
        :file => "/path/to/file", :statistics => {"Saturated Spots" => "0"}

      response.should be_success
    end

    it "should not be successful if the QC Set saves successfully" do
      qc_set = mock_model(QcSet, :save => false)
      QcSet.should_receive(:new).with(
        :chip_name => "20100526_01", :array_number => "1",
        :file => "/path/to/file", :statistics => {"Saturated Spots" => "0"}
      ).and_return qc_set

      post :create, :chip_name => "20100526_01", :array_number => "1",
        :file => "/path/to/file", :statistics => {"Saturated Spots" => "0"}

      response.should_not be_success
    end
  end
end
