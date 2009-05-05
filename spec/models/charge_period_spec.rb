require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChargePeriod" do
  fixtures :charge_periods, :charge_sets

  describe "providing a destroy warning" do

    it "should list the charge sets that will be destroyed" do
      expected_warning = "Destroying this charge period will also destroy:\n" + 
                         "3 charge set(s)\n" +
                         "Are you sure you want to destroy it?"
    
      period = ChargePeriod.find( charge_periods(:january) )   
      period.destroy_warning.should == expected_warning
    end
  end

  describe "converting to a PDF" do
    
    it "should produce a PDF::Writer object"  do
      pdf = charge_periods(:january).to_pdf
      pdf.class.should == PDF::Writer
    end

  end

  describe "converting to an Excel file" do
    
    it "should produce an Excel file"  do
      excel_file = charge_periods(:january).to_excel
      File.exist?(excel_file).should be_true
    end

  end
end
