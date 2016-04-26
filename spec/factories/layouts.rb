# See README.md for copyright details

FactoryGirl.define do
  factory :layout do
    sequence(:name) { |n| "Layout name_#{n}"}
  end
end
