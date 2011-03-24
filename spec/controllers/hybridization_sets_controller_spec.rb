require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HybridizationSetsController do

  describe "POST 'new'" do
    before(:each) do
      @platform = mock_model(Platform, :uses_chip_numbers => false)
      @chip_type = mock_model(ChipType, :platform => @platform)
      @sample_set = mock_model(SampleSet, :chip_type => @chip_type)
      @chip = mock_model(Chip, :sample_set => @sample_set)
      Chip.stub!(:find).and_return(@chip)
    end

    def do_post
      post 'new', :chip => {"123" => "1", "546" => "0"}
    end

    it "find the selected chips" do
      Chip.should_receive(:find).with("123").and_return(@chip)
      do_post
    end

    it "assigns the selected chips to the view" do
      do_post
      assigns(:chips).should == [@chip]
    end

    it "renders the 'new' template" do
      do_post
      response.should render_template('new')
    end
  end

  describe "POST 'create'" do
    before(:each) do
      @hybridization_set = mock_model(HybridizationSet)
      HybridizationSet.stub!(:new).and_return(@hybridization_set)
      @hybridization_set.stub!(:save).and_return(true)
    end

    def do_post
      post 'create', :hybridization_set => "Hybridization set parameters"
    end

    it "instantiates a hybridization set using the posted parameters" do
      HybridizationSet.should_receive(:new).with("Hybridization set parameters").and_return(@hybridization_set)
      do_post
    end

    it "renders the 'show' template on a successful save" do
      @hybridization_set.should_receive(:save).and_return(true)
      do_post
      response.should render_template('show')
    end

    it "renders the 'new' template on a failed save" do
      @hybridization_set.should_receive(:save).and_return(false)
      do_post
      response.should render_template('new')
    end
  end
end
