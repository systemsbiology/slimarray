require 'spec_helper'

describe ChipsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
  end

  describe "GET 'edit'" do
    before(:each) do
      @chip = mock_model(Chip)
      @layout = mock("Layout")
      @available_sample = mock("Available Samples")
      Chip.stub!(:find).and_return(@chip)
      @chip.stub!(:layout).and_return(@layout)
      @chip.stub!(:available_samples).and_return(@available_samples)
    end

    it "finds the chip" do
      Chip.should_receive(:find).with("23").and_return(@chip)
      get 'edit', :id => "23"
    end

    it "generates the chip layout" do
      @chip.should_receive(:layout).and_return(@layout)
      get 'edit', :id => "23"
    end
      
    it "loads available samples" do
      @chip.should_receive(:available_samples).and_return(@available_samples)
      get 'edit', :id => "23"
    end
  end

  describe "PUT 'update'" do
    before(:each) do
      @chip = mock_model(Chip)
      Chip.should_receive(:find).with("23").and_return(@chip)
      @available_sample = mock("Available Samples")
      @chip.stub!(:available_samples).and_return(@available_samples)
    end

    def do_put
      put 'update', :id => "23", :chip => "Chip attributes"
    end

    describe "with valid parameters" do
      before(:each) do
        @chip.stub!(:update_attributes).and_return(true)
        @chip.stub!(:layout)
      end

      it "updates the attributes successfully" do
        @chip.should_receive(:update_attributes).with("Chip attributes").and_return(true)
        do_put
      end

      it "loads the chip layout" do
        @chip.should_receive(:layout)
        do_put
      end

      it "renders the edit template" do
        do_put
        response.should render_template('edit')
      end
    end
  end

  describe "DELETE 'delete'" do
    before(:each) do
      @chip = mock_model(Chip)
      Chip.stub!(:find).with("24").and_return(@chip)
      @chip.stub!(:destroy)
    end

    def do_delete
      delete 'destroy', :id => "24"
    end

    it "should find the chip" do
      Chip.should_receive(:find).with("24").and_return(@chip)
      do_delete
    end

    it "should destroy the chip" do
      @chip.should_receive(:destroy)
      do_delete
    end

    it "should redirect to the root url" do
      do_delete
      response.should redirect_to(root_url)
    end
  end
end
