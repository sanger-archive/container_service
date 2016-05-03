# See README.md for copyright details
require 'uuid'

namespace :labwares do
  def create_labware
    layout_plate_96_test = Layout.new(name: "test_layout_plate_96")
    locations = []
    ('A'..'H').each do |row|
      (1..12).each do |col|
        layout_plate_96_test.locations << Location.new(name: "#{row}#{col}")
      end
    end
    layout_plate_96_test.save!
    labware_type = LabwareType.create!(name: "test_plate_96", layout: layout_plate_96_test)

    labware = Labware.new(barcode_prefix: "TEST", labware_type: labware_type)

    layout_plate_96_test.locations.each { |location|
      labware.receptacles << Receptacle.new(location: location)
    }
    labware.save!
    labware
  end

  desc "create a labware for testing"
  task :create_empty => :environment do |t|
    create_labware
  end

  desc "create a labware with material for testing"
  task :create_with_material => :environment do |t|
    labware = create_labware
    labware.receptacles.each { |receptacle|
      receptacle.update!( material_uuid: UUID.new.generate)
    }
  end

end