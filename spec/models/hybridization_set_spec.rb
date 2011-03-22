require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HybridizationSet do
  before(:each) do
    @chip_1 = create_chip
    @chip_2 = create_chip
  end

  it "initialized a new hybridization set" do
    hybridization_set = HybridizationSet.new(
      "chips" => {
        "0" => {
          "id" => @chip_1.id, "name" => "1234"
        },
        "1" => {
          "id" => @chip_2.id, "name" => "5678"
        }
    })

    hybridization_set.chips[0].name.should == "1234"
    hybridization_set.chips[1].name.should == "5678"
  end

  it "saves a hybridization set" do
    hybridization_set = HybridizationSet.new(
      "chips" => {
        "0" => {
          "id" => @chip_1.id, "name" => "1234"
        },
        "1" => {
          "id" => @chip_2.id, "name" => "5678"
        }
    })
    hybridization_set.should_receive(:record_chip_transactions)
    hybridization_set.save

    @chip_1.reload.attributes.should include("status" => "hybridized", "name" => "1234",
      "hybridization_date" => Date.today)
    @chip_2.reload.attributes.should include("status" => "hybridized", "name" => "5678",
      "hybridization_date" => Date.today)
  end

  describe "recording chip transactions" do
    def do_record
      @hybridization_set = HybridizationSet.new(
        "chips" => {
          "0" => {
            "id" => @chip_1.id, "name" => "1234"
          },
          "1" => {
            "id" => @chip_2.id, "name" => "5678"
          }
      })
      @hybridization_set.save
    end

    it "should create a single transaction for chips with the same date/lab/chip type" do
      project = create_project
      chip_type = create_chip_type
      sample_set = create_sample_set(:project => project, :chip_type => chip_type)
      sample_set.chips << @chip_1
      sample_set.chips << @chip_2

      do_record

      chip_transactions = ChipTransaction.find(:all, :conditions => {
        :lab_group_id => project.lab_group_id, :chip_type_id => chip_type.id})

      chip_transactions.size.should == 1
      chip_transactions[0].lab_group_id.should == project.lab_group_id
      chip_transactions[0].chip_type_id.should == chip_type.id
      chip_transactions[0].used.should == 2
    end

    it "should create two transaction when hybridizations span different labs/chips" do
      project_1 = create_project
      project_2 = create_project
      chip_type = create_chip_type
      sample_set_1 = create_sample_set(:project => project_2, :chip_type => chip_type)
      sample_set_1.chips << @chip_1
      sample_set_2 = create_sample_set(:project => project_2, :chip_type => chip_type)
      sample_set_2.chips << @chip_2

      do_record

      chip_transactions_1 = ChipTransaction.find(:all, :conditions => {
        :lab_group_id => project_1.lab_group_id, :chip_type_id => chip_type.id})
      chip_transactions_1.size.should == 1

      chip_transactions_2 = ChipTransaction.find(:all, :conditions => {
        :lab_group_id => project_2.lab_group_id, :chip_type_id => chip_type.id})
      chip_transactions_2.size.should == 1
    end
  end

end
