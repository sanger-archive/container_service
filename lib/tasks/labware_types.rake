# See README.md for copyright details

namespace :labware_types do
  desc "create 3 labware_types for testing"
  task :create => :environment do |t|
    layout_plate_96_test = Layout.new(name: "test_layout_plate_96")
    ('A'..'H').each do |row|
      (1..12).each do |col|
        layout_plate_96_test.locations << Location.create!(name: "#{row}#{col}")
      end
    end
    layout_plate_96_test.save!
    LabwareType.create!(name: "test_plate_96", layout: layout_plate_96_test)
  end
end