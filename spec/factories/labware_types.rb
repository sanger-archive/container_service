# See README.md for copyright details

FactoryGirl.define do
  factory :labware_type do
    sequence(:name) { |n| "Labware type name_#{n}" }
    layout { build :layout_with_locations }
  end
end