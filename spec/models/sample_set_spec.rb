require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleSet do

  before(:each) do
    @naming_scheme = create_naming_scheme
    @naming_element = create_naming_element(:naming_scheme => @naming_scheme, :name => "Sample Key")
    @yo1 = create_naming_term(:naming_element => @naming_element, :term => "YO 1", :abbreviated_term => "YO1")
    @yo2 = create_naming_term(:naming_element => @naming_element, :term => "YO 2", :abbreviated_term => "YO2")
    @chip_type = create_chip_type
    @service_option = create_service_option
    @label = create_label
    @project = create_project
  end

  describe "making a new sample set with parameters parameters submitted from the HTML form" do
    it "creates a new sample set" do
      Notifier.should_receive(:deliver_sample_submission_notification)
      #Notifier.should_receive(:deliver_approval_request)
      Notifier.should_receive(:deliver_low_inventory_notification)

      sample_set = SampleSet.parse_api( 
        { 
          "submission_date(1i)" => "2010",
          "submission_date(2i)" => "11",
          "submission_date(3i)" => "19",
          #"naming_scheme_id" => @naming_scheme.id,
          "next_step" => "samples",
          "number" => "2",
          "chip_type_id" => @chip_type.id,
          "service_option_id" => @service_option.id,
          "submitted_by" => "bmarzolf",
          "chips_attributes" => {
            "1" => {
              "microarrays_attributes" => {
                "1" => {
                  "samples_attributes" => {
                    "1"=>{
                      "short_sample_name"=>"RM11-1a pbp1::URA3",
                      "sample_name" => "S1",
                      "sample_group_name" => "S",
                      "organism_id" => @chip_type.organism_id,
                      "label_id" => @label.id,
                      #"schemed_name"=>{"SampleKey"=>"YO 1"}
                      "project_id" => @project.id,
                    }
                  }
                },
                "2" => {
                  "samples_attributes" => {
                    "1"=>{
                      "short_sample_name"=>"DBVPG 1373",
                      "sample_name" => "S2",
                      "sample_group_name" => "S",
                      "organism_id" => @chip_type.organism_id,
                      "label_id" => @label.id,
                      #"schemed_name"=>{"SampleKey"=>"YO 2"}
                      "project_id" => @project.id,
                    }
                  }
                }
              }
            }
          }
        }
      )
      sample_set.should be_valid
      
      sample_set.attributes.should include({
        "submitted_by" => "bmarzolf",
        "submission_date" => Date.parse("2010-11-19"),
        "chip_type_id" => @chip_type.id,
        "service_option_id" => @service_option.id,
      })

      chip = sample_set.chips.first
      chip.microarrays[0].samples[0].attributes.should include({
        "short_sample_name"=>"RM11-1a pbp1::URA3",
        "sample_name" => "S1",
        "sample_group_name" => "S",
        "organism_id" => @chip_type.organism_id,
        "label_id" => @label.id,
      })

      chip.microarrays[1].samples[0].attributes.should include({
        "short_sample_name"=>"DBVPG 1373",
        "sample_name" => "S2",
        "sample_group_name" => "S",
        "organism_id" => @chip_type.organism_id,
        "label_id" => @label.id,
      })

      sample_set.save.should be_true
    end
  end

end
