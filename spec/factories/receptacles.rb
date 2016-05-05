# See README.md for copyright details

FactoryGirl.define do
  factory :receptacle do
    after(:build) do |receptacle, evaluator|
      if receptacle.labware
        receptacle.location ||= receptacle.labware.labware_type.layout.locations.first
      end
    end

    association :labware, strategy: :build

    factory :receptacle_with_labware, parent: :receptacle do
      labware
    end
    
  end
end
