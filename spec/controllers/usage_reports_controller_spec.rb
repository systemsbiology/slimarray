require 'spec_helper'

describe UsageReportsController do

  describe "GET 'new'" do
    it "renders the new template" do
      get 'new'
      response.should render_template('new')
    end
  end

  describe "POST 'create'" do
    before(:each) do
      @stats = mock("Some statistics")
      ServiceOption.stub!(:usage_between).and_return(@stats)
    end

    def do_post
      post :create, "usage_report" => {"start_date(1i)" => "2010", "start_date(2i)" => "01", "start_date(3i)" => "01", 
        "end_date(1i)" => "2010", "end_date(2i)" => "12", "end_date(3i)" => "31"}
    end

    it "calculates usage for the specified dates" do
      ServiceOption.should_receive(:usage_between).with("2010-01-01", "2010-12-31").and_return(@stats)
      do_post
      assigns(:stats).should == @stats
    end

    it "renders the 'show' template" do
      do_post
      response.should render_template('show')
    end
  end
end
