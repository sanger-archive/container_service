# See README.md for copyright details

FactoryGirl.define do
  factory :layout do
    sequence(:name) { |n| "Layout name_#{n}"}

    factory :layout_with_locations, parent: :layout do
      locations { build_list :location, 10 }
    end
  end
end
