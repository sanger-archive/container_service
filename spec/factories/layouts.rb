# See README.md for copyright details

FactoryGirl.define do
  factory :layout do
    sequence(:name) { |n| "Layout name_#{n}"}
    row {rand(1..32)}
    column {rand(1..48)}

    after(:build) do |layout, evaluator|
      build_list(:location, 10, layout: layout)
    end

    factory :layout_with_locations, parent: :layout do
      locations { build_list :location, 10 }
    end
  end
end
