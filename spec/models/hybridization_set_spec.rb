require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HybridizationSet do

  before(:each) do
    @sample_1 = create_sample
    @sample_2 = create_sample
    @sample_3 = create_sample
    @charge_set = create_charge_set
    @charge_template = create_charge_template
  end

  describe "generating hybridizations" do

    it "should provide hybridizations using the provided charge set" do
      hybridization_set = HybridizationSet.new(
        :date => "2009-07-28",
        :charge_set_id => @charge_set.id,
        :charge_template_id => @charge_template.id,
        :selected_samples => {
          @sample_1.id.to_s => '0', @sample_2.id.to_s => '1', @sample_3.id.to_s => '1'
        }
      )

      hybridizations = hybridization_set.hybridizations(
        :available_samples => [@sample_1, @sample_2, @sample_3],
        :last_hyb_number => 0
      )

      expected_hybridizations = {
        0 => { :hybridization_date => Date.parse("2009-07-28"),
               :chip_number => 1,
               :charge_set_id => @charge_set.id,
               :charge_template_id => @charge_template.id,
               :sample_id => @sample_2.id },
        1 => { :hybridization_date => Date.parse("2009-07-28"),
               :chip_number => 2,
               :charge_set_id => @charge_set.id,
               :charge_template_id => @charge_template.id,
               :sample_id => @sample_3.id }
      }

      expected_hybridizations.each do |index, values|
        values.each do |key, value|
          hybridizations[index][key].should == value
        end
      end
    end

    it "should provide hybridizations using a charge set when none is provided" do
      hybridization_set = HybridizationSet.new(
        :date => "2009-07-28",
        :charge_set_id => -1,
        :charge_template_id => @charge_template.id,
        :selected_samples => {
          @sample_1.id.to_s => '0', @sample_2.id.to_s => '1', @sample_3.id.to_s => '1'
        }
      )

      ChargeSet.should_receive(:new).and_return(@charge_set)

      hybridizations = hybridization_set.hybridizations(
        :available_samples => [@sample_1, @sample_2, @sample_3],
        :last_hyb_number => 0
      )

      expected_hybridizations = {
        0 => { :hybridization_date => Date.parse("2009-07-28"),
               :chip_number => 1,
               :charge_set_id => @charge_set.id,
               :charge_template_id => @charge_template.id,
               :sample_id => @sample_2.id },
        1 => { :hybridization_date => Date.parse("2009-07-28"),
               :chip_number => 2,
               :charge_set_id => @charge_set.id,
               :charge_template_id => @charge_template.id,
               :sample_id => @sample_3.id }
      }

      expected_hybridizations.each do |index, values|
        values.each do |key, value|
          hybridizations[index][key].should == value
        end
      end
    end

  end

  it "should provide the number of hybridizations" do
    hybridization_set = HybridizationSet.new(
      :date => "2009-07-28",
      :charge_set_id => @charge_set.id,
      :charge_template_id => @charge_template.id,
      :selected_samples => {
        @sample_1.id.to_s => '0', @sample_2.id.to_s => '1', @sample_3.id.to_s => '1'
      }
    )
    hybridization_set.number.should == 0

    hybridizations = hybridization_set.hybridizations(
      :available_samples => [@sample_1, @sample_2, @sample_3],
      :last_hyb_number => 0
    )
    hybridization_set.number.should == 2
  end

end
