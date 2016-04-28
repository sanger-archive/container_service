FactoryGirl.define do
  factory :labware do
    labware_type
    barcode_prefix 'TEST'
    sequence(:external_id) { |n| "TICKET_#{n}" }
  end
end
