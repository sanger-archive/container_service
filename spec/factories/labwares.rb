require 'uuid'

FactoryGirl.define do
  factory :labware do
    labware_type
    barcode_prefix 'TEST'
    sequence(:external_id) { |n| "TICKET_#{n}" }

    after(:build) do |labware, evaluator|
      if labware.labware_type
        labware.labware_type.layout.locations { |location| 
          build(:receptacle, labware: labware, location: location)
        }
      end
    end

    factory :labware_with_receptacles, parent: :labware do
      receptacles_attributes { labware_type.layout.locations.map { |location| 
        {location: location}
      }}
    end

    factory :labware_with_receptacles_with_material, parent: :labware do
      receptacles_attributes { labware_type.layout.locations.map { |location| 
        {location: location, material_uuid: UUID.new.generate}
      }}
    end
  end
end
