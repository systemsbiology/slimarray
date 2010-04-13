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
      :platform => Platform.find_or_create_by_name("Affymetrix"),
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
      :platform => Platform.find_or_create_by_name("Affymetrix"),
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
end
