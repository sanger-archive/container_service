# See README.md for copyright details

namespace :labwares do
  desc "create a labware for testing"
  task :create => :environment do |t|
    layout_plate_96_test = Layout.new(name: "test_layout_plate_96")
    locations = []
    ('A'..'H').each do |row|
      (1..12).each do |col|
        layout_plate_96_test.locations << Location.create!(name: "#{row}#{col}")
      end
    end
    layout_plate_96_test.save!
    labware_type = LabwareType.create!(name: "test_plate_96", layout: layout_plate_96_test)

    labware = Labware.create!(barcode: "test_barcode", labware_type: labware_type)

    layout_plate_96_test.locations.each { |location|
      Receptacle.create!(labware: labware, location: location)
    }
  end
end