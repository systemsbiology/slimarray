require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChipType" do
  fixtures :chip_types, :samples, :hybridizations, :inventory_checks, :chip_transactions

  it "destroy warning" do
    expected_warning = "Destroying this chip type will also destroy:\n" + 
                       "6 sample(s)\n" +
                       "2 inventory check(s)\n" +
                       "2 chip transaction(s)\n" +
                       "Are you sure you want to destroy it?"
  
    type = ChipType.find( chip_types(:alligator) )   
    type.destroy_warning.should == expected_warning
  end

  it "should provide a summary hash for a chip type" do
    organism = create_organism(:name => "Rat")
    chip_type = create_chip_type(
      :name => "Mouse Exon",
      :short_name => "MoEx",
      :organism => organism
    )
    
    chip_type.summary_hash.should == {
      :id => chip_type.id,
      :name => "Mouse Exon",
      :short_name => "MoEx",
      :array_platform => "Affymetrix",
      :organism => "Rat",
      :updated_at => chip_type.updated_at,
      :uri => "#{SiteConfig.site_url}/chip_types/#{chip_type.id}"
    }
  end

  it "should provide a detail hash for a chip type" do
    organism = create_organism(:name => "Rat")
    chip_type = create_chip_type(
      :name => "Mouse Exon",
      :short_name => "MoEx",
      :organism => organism
    )
    
    chip_type.detail_hash.should == {
      :id => chip_type.id,
      :name => "Mouse Exon",
      :short_name => "MoEx",
      :array_platform => "Affymetrix",
      :organism => "Rat",
      :updated_at => chip_type.updated_at,
    }
  end

  it "should provide the total number of chips in inventory" do
    mouse_chip_type = create_chip_type
    create_chip_transaction(:chip_type => mouse_chip_type, :acquired => 30)
    create_chip_transaction(:chip_type => mouse_chip_type, :used => 5)
    create_chip_transaction(:chip_type => mouse_chip_type, :traded_sold => 6)
    create_chip_transaction(:chip_type => mouse_chip_type, :borrowed_in => 4)
    create_chip_transaction(:chip_type => mouse_chip_type, :returned_out => 4)
    create_chip_transaction(:chip_type => mouse_chip_type, :borrowed_out => 10)
    create_chip_transaction(:chip_type => mouse_chip_type, :returned_in => 6)

    mouse_chip_type.total_inventory.should == 15
  end
end
