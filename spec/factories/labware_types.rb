# See README.md for copyright details

FactoryGirl.define do
  factory :labware_type do
    sequence(:name) { |n| "Labware type name_#{n}" }
  end
end