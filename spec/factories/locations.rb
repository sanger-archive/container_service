# See README.md for copyright details

FactoryGirl.define do
  factory :location do
    sequence(:name) { |n| "Location name_#{n}"}

    factory :location_with_layout, parent: :location do
      layout
    end
  end
end