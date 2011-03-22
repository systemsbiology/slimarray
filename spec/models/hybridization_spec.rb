require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hybridization do

#  describe "providing the highest chip number for a particular date" do
#
#    it "should provide 0 if there are no hybridizations on that date" do
#      Hybridization.highest_chip_number('2009-06-30').should == 0
#    end
#
#    it "should provide the highest chip_number for that date if hybridiations exist" do
#      create_hybridization(:hybridization_date => '2009-06-29', :chip_number => 1)
#      create_hybridization(:hybridization_date => '2009-06-29', :chip_number => 2)
#
#      Hybridization.highest_chip_number('2009-06-29').should == 2
#    end
#
#  end
#
#  describe "recording charges for a set of hybridizations" do
#    before(:each) do
#      @service_option = create_service_option(
#        :chip_cost => 100,
#        :labeling_cost => 200,
#        :hybridization_cost => 25,
#        :qc_cost => 0,
#        :other_cost => 0
#      )
#      @charge_set = create_charge_set
#      @sample_1 = create_sample(:sample_name => "wt-0", :service_option => @service_option)
#      @sample_2 = create_sample(:sample_name => "mut-0", :service_option => @service_option)
#      @sample_3 = create_sample(:sample_name => "wt-5", :service_option => @service_option)
#      @sample_4 = create_sample(:sample_name => "mut-5", :service_option => @service_option)
#      @charge_period = create_charge_period
#      ChargeSet.should_receive(:find_or_create_by_charge_period_id_and_lab_group_id_and_name).
#        twice.and_return(@charge_set)
#    end
#
#    it "should handle one channel array hybridizations" do
#      hybridization_1 = create_hybridization(
#        :hybridization_date => "2009-12-11",
#        :chip_number => 1,
#        :charge_template => @charge_template,
#        :charge_set => nil,
#        :samples => [@sample_1]
#      )
#      hybridization_2 = create_hybridization(
#        :hybridization_date => "2009-12-11",
#        :chip_number => 2,
#        :charge_template => @charge_template,
#        :charge_set => nil,
#        :samples => [@sample_2]
#      )
#      Charge.should_receive(:create).with(
#        :charge_set_id => @charge_set.id,
#        :date => Date.parse("2009-12-11"),
#        :description => "wt-0",
#        :chips_used => 1,
#        :chip_cost => 100.0,
#        :labeling_cost => 200.0,
#        :hybridization_cost => 25.0,
#        :qc_cost => 0.0,
#        :other_cost => 0.0
#      )
#      Charge.should_receive(:create).with(
#        :charge_set_id => @charge_set.id,
#        :date => Date.parse("2009-12-11"),
#        :description => "mut-0",
#        :chips_used => 1,
#        :chip_cost => 100.0,
#        :labeling_cost => 200.0,
#        :hybridization_cost => 25.0,
#        :qc_cost => 0.0,
#        :other_cost => 0.0
#      )
#      Hybridization.record_charges([hybridization_1, hybridization_2]) 
#    end
#
#    it "should handle two channel array hybridizations" do
#      hybridization_1 = create_hybridization(
#        :hybridization_date => "2009-12-11",
#        :chip_number => 1,
#        :charge_template => @charge_template,
#        :charge_set => nil,
#        :samples => [@sample_1,@sample_2]
#      )
#      hybridization_2 = create_hybridization(
#        :hybridization_date => "2009-12-11",
#        :chip_number => 2,
#        :charge_template => @charge_template,
#        :charge_set => nil,
#        :samples => [@sample_3,@sample_4]
#      )
#      Charge.should_receive(:create).with(
#        :charge_set_id => @charge_set.id,
#        :date => Date.parse("2009-12-11"),
#        :description => "mut-0_v_wt-0",
#        :chips_used => 1,
#        :chip_cost => 100.0,
#        :labeling_cost => 200.0,
#        :hybridization_cost => 25.0,
#        :qc_cost => 0.0,
#        :other_cost => 0.0
#      )
#      Charge.should_receive(:create).with(
#        :charge_set_id => @charge_set.id,
#        :date => Date.parse("2009-12-11"),
#        :description => "mut-5_v_wt-5",
#        :chips_used => 1,
#        :chip_cost => 100.0,
#        :labeling_cost => 200.0,
#        :hybridization_cost => 25.0,
#        :qc_cost => 0.0,
#        :other_cost => 0.0
#      )
#      Hybridization.record_charges([hybridization_1, hybridization_2]) 
#    end
#  end
#
#  describe "providing the sample names" do
#    it "should provide the sample name when there is just one sample" do
#      sample = create_sample(:sample_name => "Time_0")
#      hybridization = create_hybridization(:samples => [sample])
#
#      hybridization.sample_names.should == "Time_0"
#    end
#
#    it "should provide the sample names in alphanumeric order for 2 samples" do
#      label_b = create_label(:name => "b")
#      label_a = create_label(:name => "a")
#      sample_1 = create_sample(:sample_name => "Time_0", :label => label_a)
#      sample_2 = create_sample(:sample_name => "Time_60", :label => label_b)
#      hybridization = create_hybridization(:samples => [sample_2, sample_1])
#
#      hybridization.sample_names.should == "Time_0_v_Time_60"
#    end
#  end
end
