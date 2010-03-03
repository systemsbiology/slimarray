require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HybridizationSet do

  before(:each) do
    @no_multi_array_platform = create_platform(:has_multi_array_chips => false)
    @multi_array_platform = create_platform(:has_multi_array_chips => true)
    @no_multi_array_chip_type = create_chip_type(:platform => @no_multi_array_platform)
    @multi_array_chip_type = create_chip_type
    @sample_1 = create_sample(:chip_type => @no_multi_array_chip_type, :status => "submitted")
    @sample_2 = create_sample(:chip_type => @no_multi_array_chip_type, :status => "submitted")
    @sample_3 = create_sample
    @charge_set = create_charge_set
    @charge_template = create_charge_template
  end

  describe "determining the current step in producing a hybridization set" do

    it "should be on step 1 with no validations when no previous step is indicated" do
      hs = HybridizationSet.new
      hs.step.should == "step1"
    end

    it "should be on step 1 if no platform or date is provided" do
      hs = HybridizationSet.new(:previous_step => "step1")
      hs.step.should == "step1"
    end

    describe "with a non-multi-array platform" do

      it "should be on step 2 if step 1 is complete" do
        hs = HybridizationSet.new(
          :previous_step => "step1",
          :platform_id => @no_multi_array_platform.id,
          :date => Date.today
        )
        hs.step.should == "step2_no_multi_arrays"
      end
      
      it "should be on step 3 if step 2 is complete" do
        hs = HybridizationSet.new(
          :previous_step => "step2_no_multi_arrays",
          :platform_id => @no_multi_array_platform.id,
          :date => Date.today,
          :charge_template_id => @charge_template.id,
          :number_of_chips => 4,
          :number_of_channels => 1
        )
        hs.step.should == "step3_no_multi_arrays"
      end

    end

    describe "with a multi-array platform" do
    
      it "should be on step 2 if step 1 is complete" do
        hs = HybridizationSet.new(
          :previous_step => "step1",
          :platform_id => @multi_array_platform.id,
          :date => Date.today
        )
        hs.step.should == "step2_with_multi_arrays"
      end
      
      it "should be on step 3 if step 2 is complete" do
        hs = HybridizationSet.new(
          :previous_step => "step2_with_multi_arrays",
          :platform_id => @multi_array_platform.id,
          :date => Date.today,
          :charge_template_id => @charge_template.id,
          :number_of_chips => 4,
          :chip_type_id => @no_multi_array_chip_type.id,
          :number_of_channels => 1
        )
        hs.step.should == "step3_with_multi_arrays"
      end

    end
  end

  describe "providing the current platform" do
    
    it "should be nil if platform_id is nil" do
      hs = HybridizationSet.new
      hs.platform.should be_nil
    end

    it "should be nil if the platform_id doesn't map to an actual platform id" do
      hs = HybridizationSet.new(:platform_id => 1234)
      hs.platform.should be_nil
    end
    
    it "should provide the platform when the id is valid" do
      Platform.should_receive(:find).with(42).and_return(@multi_array_platform)
      hs = HybridizationSet.new(:platform_id => 42)
      hs.platform.should == @multi_array_platform
    end

  end

  describe "determining whether multi arrays are in use" do

    it "should be nil when there is no platform" do
      hs = HybridizationSet.new
      hs.multi_arrays.should be_nil
    end

    it "should be false when the platform does not have multi arrays" do
      Platform.should_receive(:find).with(42).and_return(@no_multi_array_platform)
      hs = HybridizationSet.new(:platform_id => 42)
      hs.multi_arrays.should be_false
    end

    it "should be false when the platform does not have multi arrays" do
      Platform.should_receive(:find).with(42).and_return(@multi_array_platform)
      hs = HybridizationSet.new(:platform_id => 42)
      hs.multi_arrays.should be_true
    end

  end

  it "should provide the samples available for hybridization with the current platform" do
    hs = HybridizationSet.new
    hs.should_receive(:platform).and_return(@no_multi_array_platform)
    hs.available_samples.should == [@sample_1, @sample_2]    
  end

  it "should provide the chip types for the current platform" do
    hs = HybridizationSet.new
    hs.should_receive(:platform).and_return(@no_multi_array_platform)
    hs.chip_types.should == [@no_multi_array_chip_type]    
  end

  describe "saving without multi arrays and a single channel" do
    describe "without chip names" do
      before(:each) do
        @chip_1 = create_chip(:name => "20091108_01")
        @chip_2 = create_chip(:name => "20091108_02")
        @microarray_1 = create_microarray(:chip => @chip_1)
        @microarray_2 = create_microarray(:chip => @chip_2)
        @sample_1 = create_sample(:chip_type => @no_multi_array_chip_type, :microarray => @microarray_1)
        @sample_2 = create_sample(:chip_type => @no_multi_array_chip_type, :microarray => @microarray_2)
        @hybridization_1 = create_hybridization(:chip_number => 1)
        @hybridization_2 = create_hybridization(:chip_number => 2)
        @charge_set = create_charge_set
        @hybridization_set = HybridizationSet.new(
          :date => "2009-11-18",
          :platform_id => @no_multi_array_platform.id,
          :number_of_chips => 2,
          :number_of_channels => 1,
          :charge_set_id => @charge_set.id,
          :charge_template_id => @charge_template.id,
          :sample_ids => { "0" => {"0" => @sample_1.id}, "1" => {"0" => @sample_2.id} }
        )
        Chip.stub!(:create!).with(:name => "20091118_01").
          and_return(@chip_1)
        Chip.stub!(:create!).with(:name => "20091118_02").
          and_return(@chip_2)
        Microarray.stub!(:create!).
          with(:chip_id => @chip_1.id, :array_number => 1).
          and_return(@microarray_1)
        Microarray.stub!(:create!).
          with(:chip_id => @chip_2.id, :array_number => 1).
          and_return(@microarray_2)
        Hybridization.stub!(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 1,
          :microarray_id => @microarray_1.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_1]
        ).and_return(@hybridization_1)
        Hybridization.stub!(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 2,
          :microarray_id => @microarray_2.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_2]
        ).and_return(@hybridization_2)
        Hybridization.stub!(:record_charges)
        Hybridization.stub!(:record_as_chip_transactions)
      end

      it "should create a new chip for each sample" do
        Chip.should_receive(:create!).with(:name => "20091118_01").
          once.and_return(@chip_1)
        Chip.should_receive(:create!).with(:name => "20091118_02").
          once.and_return(@chip_2)
        @hybridization_set.save
      end

      it "should create a new hybridization for each sample" do
        Hybridization.should_receive(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 1,
          :microarray_id => @microarray_1.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_1]
        ).once.and_return(@hybridization_1)
        Hybridization.should_receive(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 2,
          :microarray_id => @microarray_2.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_2]
        ).once.and_return(@hybridization_2)
        @hybridization_set.save
      end

      it "should record charges if that option is enabled in the site configuration" do
        SiteConfig.should_receive(:track_charges?).and_return(true)
        Hybridization.should_receive(:record_charges).
          with([@hybridization_1, @hybridization_2])
        @hybridization_set.save
      end

      it "should record chip transactions if that option is enabled in the site configuration" do
        SiteConfig.should_receive(:track_inventory?).and_return(true)
        Hybridization.should_receive(:record_as_chip_transactions).
          with([@hybridization_1, @hybridization_2])
        @hybridization_set.save
      end

      it "should return false and store an appropriate message if a duplication error occurs" do
        mock_record = mock( :errors => mock(:full_messages => ["Duplicate stuff"]) )
        Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
        @hybridization_set.save.should be_false
        @hybridization_set.array_entry_errors.should == "One or more of these chip numbers have already been used for this date: 2009-11-18"
      end

      it "should return false and store a general message if an unexpected error occurs" do
        mock_record = mock( :errors => mock(:full_messages => ["unexpected error"]) )
        Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
        @hybridization_set.save.should be_false
        @hybridization_set.array_entry_errors.should == "Something went horribly wrong. Check " +
          "with your SLIMarray administrator on this one."
      end
    end

    describe "with chip names" do
      before(:each) do
        @chip_1 = create_chip(:name => "20091108_01")
        @chip_2 = create_chip(:name => "20091108_02")
        @microarray_1 = create_microarray(:chip => @chip_1)
        @microarray_2 = create_microarray(:chip => @chip_2)
        @sample_1 = create_sample(:chip_type => @no_multi_array_chip_type, :microarray => @microarray_1)
        @sample_2 = create_sample(:chip_type => @no_multi_array_chip_type, :microarray => @microarray_2)
        @hybridization_1 = create_hybridization(:chip_number => 1)
        @hybridization_2 = create_hybridization(:chip_number => 2)
        @charge_set = create_charge_set
        @hybridization_set = HybridizationSet.new(
          :date => "2009-11-18",
          :platform_id => @no_multi_array_platform.id,
          :number_of_chips => 2,
          :number_of_channels => 1,
          :charge_set_id => @charge_set.id,
          :charge_template_id => @charge_template.id,
          :sample_ids => { "0" => {"0" => @sample_1.id}, "1" => {"0" => @sample_2.id} },
          :chip_names => { "0" => "1002", "1" => "1001" }
        )
        Chip.stub!(:create!).with(:name => "1002").
          and_return(@chip_1)
        Chip.stub!(:create!).with(:name => "1001").
          and_return(@chip_2)
        Microarray.stub!(:create!).
          with(:chip_id => @chip_1.id, :array_number => 1).
          and_return(@microarray_1)
        Microarray.stub!(:create!).
          with(:chip_id => @chip_2.id, :array_number => 1).
          and_return(@microarray_2)
        Hybridization.stub!(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 1,
          :microarray_id => @microarray_1.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_1]
        ).and_return(@hybridization_1)
        Hybridization.stub!(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 2,
          :microarray_id => @microarray_2.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_2]
        ).and_return(@hybridization_2)
        Hybridization.stub!(:record_charges)
        Hybridization.stub!(:record_as_chip_transactions)
      end

      it "should create a new chip for each sample" do
        Chip.should_receive(:create!).with(:name => "1002").
          once.and_return(@chip_1)
        Chip.should_receive(:create!).with(:name => "1001").
          once.and_return(@chip_2)
        @hybridization_set.save
      end

      it "should create a new hybridization for each sample" do
        Hybridization.should_receive(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 1,
          :microarray_id => @microarray_1.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_1]
        ).once.and_return(@hybridization_1)
        Hybridization.should_receive(:create!).with(
          :hybridization_date => "2009-11-18",
          :chip_number => 2,
          :microarray_id => @microarray_2.id,
          :charge_template_id => @charge_template.id,
          :samples => [@sample_2]
        ).once.and_return(@hybridization_2)
        @hybridization_set.save
      end

      it "should record charges if that option is enabled in the site configuration" do
        SiteConfig.should_receive(:track_charges?).and_return(true)
        Hybridization.should_receive(:record_charges).
          with([@hybridization_1, @hybridization_2])
        @hybridization_set.save
      end

      it "should record chip transactions if that option is enabled in the site configuration" do
        SiteConfig.should_receive(:track_inventory?).and_return(true)
        Hybridization.should_receive(:record_as_chip_transactions).
          with([@hybridization_1, @hybridization_2])
        @hybridization_set.save
      end

      it "should return false and store an appropriate message if a duplication error occurs" do
        mock_record = mock( :errors => mock(:full_messages => ["Duplicate stuff"]) )
        Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
        @hybridization_set.save.should be_false
        @hybridization_set.array_entry_errors.should == "One or more of these chip numbers have already been used for this date: 2009-11-18"
      end

      it "should return false and store a general message if an unexpected error occurs" do
        mock_record = mock( :errors => mock(:full_messages => ["unexpected error"]) )
        Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
        @hybridization_set.save.should be_false
        @hybridization_set.array_entry_errors.should == "Something went horribly wrong. Check " +
          "with your SLIMarray administrator on this one."
      end
    end
  end

  describe "saving with multi arrays and a single channel" do
    
    before(:each) do
      @chip_1 = create_chip(:name => "20091108_01")
      @microarray_1 = create_microarray(:chip => @chip_1, :array_number => 1)
      @microarray_2 = create_microarray(:chip => @chip_1, :array_number => 2)
      @sample_1 = create_sample(:chip_type => @multi_array_chip_type, :microarray => @microarray_1)
      @sample_2 = create_sample(:chip_type => @multi_array_chip_type, :microarray => @microarray_1)
      @hybridization_1 = create_hybridization(:chip_number => 1, :microarray_id => @microarray_1.id)
      @hybridization_2 = create_hybridization(:chip_number => 1, :microarray_id => @microarray_2.id)
      @charge_set = create_charge_set
      @hybridization_set = HybridizationSet.new(
        :date => "2009-11-18",
        :platform_id => @multi_array_platform.id,
        :chip_type_id => @multi_array_chip_type.id,
        :number_of_chips => 2,
        :number_of_channels => 1,
        :charge_set_id => @charge_set.id,
        :charge_template_id => @charge_template.id,
        :sample_ids => { "0" => {"0" => {"0" => @sample_1.id}, "1" => {"0" => @sample_2.id}} }
      )
      Chip.stub!(:create!).with(:name => "20091118_01").
        and_return(@chip_1)
      Microarray.stub!(:create!).once.
        with(:chip_id => @chip_1.id, :array_number => 1).
        and_return(@microarray_1)
      Microarray.stub!(:create!).once.
        with(:chip_id => @chip_1.id, :array_number => 2).
        and_return(@microarray_2)
      Hybridization.stub!(:create!).once.with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_1.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_1]
      ).and_return(@hybridization_1)
      Hybridization.stub!(:create!).once.with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_2.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_2]
      ).and_return(@hybridization_2)
      Hybridization.stub!(:record_charges)
      Hybridization.stub!(:record_as_chip_transactions)
    end

    it "should create a new chip" do
      Chip.should_receive(:create!).with(:name => "20091118_01").
        once.and_return(@chip_1)
      @hybridization_set.save
    end

    it "should create a new hybridization for each sample" do
      Hybridization.should_receive(:create!).with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_1.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_1]
      ).once.and_return(@hybridization_1)
      Hybridization.should_receive(:create!).with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_2.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_2]
      ).once.and_return(@hybridization_2)
      @hybridization_set.save
    end

    it "should record charges if that option is enabled in the site configuration" do
      SiteConfig.should_receive(:track_charges?).and_return(true)
      Hybridization.should_receive(:record_charges).
        with([@hybridization_1, @hybridization_2])
      @hybridization_set.save
    end

    it "should record chip transactions if that option is enabled in the site configuration" do
      SiteConfig.should_receive(:track_inventory?).and_return(true)
      Hybridization.should_receive(:record_as_chip_transactions).
        with([@hybridization_1, @hybridization_2])
      @hybridization_set.save
    end

    it "should return false and store an appropriate message if a duplication error occurs" do
      mock_record = mock( :errors => mock(:full_messages => ["Duplicate stuff"]) )
      Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
      @hybridization_set.save.should be_false
      @hybridization_set.array_entry_errors.should == "One or more of these chip numbers have already been used for this date: 2009-11-18"
    end

    it "should return false and store a general message if an unexpected error occurs" do
      mock_record = mock( :errors => mock(:full_messages => ["unexpected error"]) )
      Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
      @hybridization_set.save.should be_false
      @hybridization_set.array_entry_errors.should == "Something went horribly wrong. Check " +
        "with your SLIMarray administrator on this one."
    end
  end

  describe "saving without multi arrays and two channels" do
    
    before(:each) do
      @chip_1 = create_chip(:name => "20091108_01")
      @microarray_1 = create_microarray(:chip => @chip_1)
      @sample_1 = create_sample(:chip_type => @no_multi_array_chip_type, :microarray => @microarray_1)
      @sample_2 = create_sample(:chip_type => @no_multi_array_chip_type, :microarray => @microarray_1)
      @hybridization_1 = create_hybridization(:chip_number => 1)
      @charge_set = create_charge_set
      @hybridization_set = HybridizationSet.new(
        :date => "2009-11-18",
        :platform_id => @no_multi_array_platform.id,
        :number_of_chips => 1,
        :number_of_channels => 2,
        :charge_set_id => @charge_set.id,
        :charge_template_id => @charge_template.id,
        :sample_ids => { "0" => {"0" => @sample_1.id, "1" => @sample_2.id} }
      )
      Chip.stub!(:create!).with(:name => "20091118_01").
        and_return(@chip_1)
      Microarray.stub!(:create!).
        with(:chip_id => @chip_1.id, :array_number => 1).
        and_return(@microarray_1)
      Hybridization.stub!(:create!).with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_1.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_1,@sample_2]
      ).and_return(@hybridization_1)
      Hybridization.stub!(:record_charges)
      Hybridization.stub!(:record_as_chip_transactions)
    end

    it "should create a new chip for each sample" do
      Chip.should_receive(:create!).with(:name => "20091118_01").
        once.and_return(@chip_1)
      @hybridization_set.save
    end

    it "should create a new hybridization for each sample" do
      Hybridization.should_receive(:create!).with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_1.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_1,@sample_2]
      ).once.and_return(@hybridization_1)
      @hybridization_set.save
    end

    it "should record charges if that option is enabled in the site configuration" do
      SiteConfig.should_receive(:track_charges?).and_return(true)
      Hybridization.should_receive(:record_charges).
        with([@hybridization_1])
      @hybridization_set.save
    end

    it "should record chip transactions if that option is enabled in the site configuration" do
      SiteConfig.should_receive(:track_inventory?).and_return(true)
      Hybridization.should_receive(:record_as_chip_transactions).
        with([@hybridization_1])
      @hybridization_set.save
    end

    it "should return false and store an appropriate message if a duplication error occurs" do
      mock_record = mock( :errors => mock(:full_messages => ["Duplicate stuff"]) )
      Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
      @hybridization_set.save.should be_false
      @hybridization_set.array_entry_errors.should == "One or more of these chip numbers have already been used for this date: 2009-11-18"
    end

    it "should return false and store a general message if an unexpected error occurs" do
      mock_record = mock( :errors => mock(:full_messages => ["unexpected error"]) )
      Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
      @hybridization_set.save.should be_false
      @hybridization_set.array_entry_errors.should == "Something went horribly wrong. Check " +
        "with your SLIMarray administrator on this one."
    end
  end

  describe "saving with multi arrays and a two channels" do
    
    before(:each) do
      @chip_1 = create_chip(:name => "20091108_01")
      @microarray_1 = create_microarray(:chip => @chip_1, :array_number => 1)
      @microarray_2 = create_microarray(:chip => @chip_1, :array_number => 2)
      @sample_1 = create_sample(:chip_type => @multi_array_chip_type, :microarray => @microarray_1)
      @sample_2 = create_sample(:chip_type => @multi_array_chip_type, :microarray => @microarray_1)
      @sample_3 = create_sample(:chip_type => @multi_array_chip_type, :microarray => @microarray_2)
      @sample_4 = create_sample(:chip_type => @multi_array_chip_type, :microarray => @microarray_2)
      @hybridization_1 = create_hybridization(:chip_number => 1, :microarray_id => @microarray_1.id)
      @hybridization_2 = create_hybridization(:chip_number => 1, :microarray_id => @microarray_2.id)
      @charge_set = create_charge_set
      @hybridization_set = HybridizationSet.new(
        :date => "2009-11-18",
        :platform_id => @multi_array_platform.id,
        :chip_type_id => @multi_array_chip_type.id,
        :number_of_chips => 2,
        :number_of_channels => 1,
        :charge_set_id => @charge_set.id,
        :charge_template_id => @charge_template.id,
        :sample_ids => { "0" => {
          "0" => {"0" => @sample_1.id,"1" => @sample_2.id},
          "1" => {"0" => @sample_3.id,"1" => @sample_4.id}
        } }
      )
      Chip.stub!(:create!).with(:name => "20091118_01").
        and_return(@chip_1)
      Microarray.stub!(:create!).once.
        with(:chip_id => @chip_1.id, :array_number => 1).
        and_return(@microarray_1)
      Microarray.stub!(:create!).once.
        with(:chip_id => @chip_1.id, :array_number => 2).
        and_return(@microarray_2)
      Hybridization.stub!(:create!).once.with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_1.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_1, @sample_2]
      ).and_return(@hybridization_1)
      Hybridization.stub!(:create!).once.with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_2.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_3, @sample_4]
      ).and_return(@hybridization_2)
      Hybridization.stub!(:record_charges)
      Hybridization.stub!(:record_as_chip_transactions)
    end

    it "should create a new chip" do
      Chip.should_receive(:create!).with(:name => "20091118_01").
        once.and_return(@chip_1)
      @hybridization_set.save
    end

    it "should create two hybridizations" do
      Hybridization.should_receive(:create!).with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_1.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_1, @sample_2]
      ).once.and_return(@hybridization_1)
      Hybridization.should_receive(:create!).with(
        :hybridization_date => "2009-11-18",
        :chip_number => 1,
        :microarray_id => @microarray_2.id,
        :charge_template_id => @charge_template.id,
        :samples => [@sample_3, @sample_4]
      ).once.and_return(@hybridization_2)
      @hybridization_set.save
    end

    it "should record charges if that option is enabled in the site configuration" do
      SiteConfig.should_receive(:track_charges?).and_return(true)
      Hybridization.should_receive(:record_charges).
        with([@hybridization_1, @hybridization_2])
      @hybridization_set.save
    end

    it "should record chip transactions if that option is enabled in the site configuration" do
      SiteConfig.should_receive(:track_inventory?).and_return(true)
      Hybridization.should_receive(:record_as_chip_transactions).
        with([@hybridization_1, @hybridization_2])
      @hybridization_set.save
    end

    it "should return false and store an appropriate message if a duplication error occurs" do
      mock_record = mock( :errors => mock(:full_messages => ["Duplicate stuff"]) )
      Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
      @hybridization_set.save.should be_false
      @hybridization_set.array_entry_errors.should == "One or more of these chip numbers have already been used for this date: 2009-11-18"
    end

    it "should return false and store a general message if an unexpected error occurs" do
      mock_record = mock( :errors => mock(:full_messages => ["unexpected error"]) )
      Chip.should_receive(:create!).and_raise( ActiveRecord::RecordInvalid.new(mock_record) )
      @hybridization_set.save.should be_false
      @hybridization_set.array_entry_errors.should == "Something went horribly wrong. Check " +
        "with your SLIMarray administrator on this one."
    end
  end
end
