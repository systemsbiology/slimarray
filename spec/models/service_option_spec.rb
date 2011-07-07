require 'spec_helper'

describe ServiceOption do
  it "provides usage statistics" do
    service_1 = create_service_option(:name => "Agilent labeling")
    service_2 = create_service_option(:name => "Affymetrix hybridization")

    lab_group_profile = mock_model(LabGroupProfile, :require_investigator_approval => false,
      :require_manager_approval => false)
    lab_group = mock_model(LabGroup, :lab_group_profile => lab_group_profile)
    project = mock_model(Project, :lab_group => lab_group)

    sample_1 = create_sample(:project => project)
    sample_2 = create_sample(:project => project)
    sample_3 = create_sample(:project => project)
    sample_4 = create_sample(:project => project)
    sample_5 = create_sample(:project => project)

    create_microarray(
      :chip => create_chip(
        :status => 'hybridized',
        :hybridization_date => '2010-04-01',
        :sample_set => create_sample_set(
          :service_option => service_1
        )
      ),
      :samples => [sample_1]
    )

    create_microarray(
      :chip => create_chip(
        :status => 'hybridized',
        :hybridization_date => '2010-06-01',
        :sample_set => create_sample_set(
          :service_option => service_1
        )
      ),
      :samples => [sample_2]
    )

    create_microarray(
      :chip => create_chip(
        :status => 'hybridized',
        :hybridization_date => '2010-04-01',
        :sample_set => create_sample_set(
          :service_option => service_2
        )
      ),
      :samples => [sample_3]
    )

    create_microarray(
      :chip => create_chip(
        :status => 'hybridized',
        :hybridization_date => '2011-04-01',
        :sample_set => create_sample_set(
          :service_option => service_1
        )
      ),
      :samples => [sample_4]
    )

    create_microarray(
      :chip => create_chip(
        :status => 'hybridized',
        :hybridization_date => '2010-04-01',
        :sample_set => create_sample_set(
          :service_option => nil
        )
      ),
      :samples => [sample_5]
    )

    ServiceOption.usage_between("2010-01-01", "2010-12-31").should == [
      {:name => "Affymetrix hybridization", :count => 1},
      {:name => "Agilent labeling", :count => 2},
      {:name => "No service option", :count => 1}
    ]
  end
end
