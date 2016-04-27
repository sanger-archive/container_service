# See README.md for copyright details

namespace :labware_types do
  desc "create 3 labware_types for testing"
  task :create => :environment do |t|
    layout_plate_96_test = Layout.create!(name: "test_layout_plate_96")
    ('A'..'H').each do |row|
      (1..12).each do |col|
        location = Location.create!(name: "#{row}#{col}", layout: layout_plate_96_test)
      end
    end
    LabwareType.create!(name: "test_plate_96", layout: layout_plate_96_test)
  end
end