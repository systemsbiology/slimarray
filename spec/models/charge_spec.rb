require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Charge" do

  describe "creating a charge from a charge template" do

    context "with a charge template that exists" do
      
      it "should use the charge template to populate the new charge" do
        template = create_charge_template(
          :name => "Yeast array",
          :chips_used => 1,
          :description => "Yeast array processing",
          :chip_cost => 100,
          :labeling_cost => 50,
          :hybridization_cost => 25,
          :qc_cost => 5,
          :other_cost => 10
        )
        charge_set = create_charge_set

        charge = Charge.from_template_id(template.id, charge_set)

        charge.charge_set_id.should == charge_set.id
        charge.chips_used.should == 1
        charge.description.should == "Yeast array processing"
        charge.chip_cost.should == 100
        charge.labeling_cost.should == 50
        charge.hybridization_cost.should == 25
        charge.qc_cost.should == 5
        charge.other_cost.should == 10
      end

    end

    context "with a non-existent charge template id" do

      it "should use empty/zero values to populate the new charge" do
        charge_set = create_charge_set

        charge = Charge.from_template_id(nil, charge_set)

        charge.charge_set_id.should == charge_set.id
        charge.chips_used.should == 0
        charge.description.should == nil
        charge.chip_cost.should == 0
        charge.labeling_cost.should == 0
        charge.hybridization_cost.should == 0
        charge.qc_cost.should == 0
        charge.other_cost.should == 0
      end

    end

  end

end
