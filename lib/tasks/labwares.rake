# See README.md for copyright details
require 'uuid'

namespace :labwares do
  def create_plate_layout(layout_name, number_of_receptacle)
    layout = Layout.find_by(name: layout_name)
    unless (layout)
      layout = Layout.create!(name: layout_name,
        locations:
          if (number_of_receptacle == 96)
            ('A'..'H').map do |row|
              (1..12).map do |col|
                 Location.new(name: "#{row}#{col}")
              end
            end.flatten
          else
            row = "A"
            (1..number_of_receptacle.to_i).map do |col|
                 Location.new(name: "#{row}#{col}")
              end
          end
      )
    end

    layout
  end

  def create_empty_plate_96(layout_name, number_of_receptacle)
    layout_plate_96_test = create_plate_layout(layout_name, number_of_receptacle)

    labware_type = LabwareType.create!(name: "test_plate_96", layout: layout_plate_96_test)

    Labware.create!(barcode_prefix: "TEST", labware_type: labware_type, 
      receptacles: layout_plate_96_test.locations.map { |location|
        Receptacle.new(location: location)
      }
    )
  end

  def add_metadata(labware, seq)
    labware.metadata << Metadatum.create!(key: "test_key_#{seq}", value: "test_value_#{seq}")
  end

  def create_empty_tube
    layout_tube_test = Layout.create!(name: "test_layout_tube", locations: [ Location.new(name: "A1") ])

    labware_type = LabwareType.create!(name: "test_tube", layout: layout_tube_test)

    Labware.create!(barcode_prefix: "TEST", labware_type: labware_type, receptacles: [ Receptacle.new(location: layout_tube_test.locations.first) ])
  end

  desc "create a 96_well_plate for testing"
  task :create_empty_plate_96, [:layout_name, :number_of_receptacle] => :environment do |t, args|
    layout_name = args[:layout_name] || "test_layout_plate_96"
    number_of_receptacle = args[:number_of_receptacle] || 96
    create_empty_plate_96(layout_name, number_of_receptacle)
  end

  desc "create a 96_well_plate with metadata for testing"
  task :create_empty_plate_96_with_metadata, [:layout_name, :number_of_receptacle] => :environment do |t, args|
    layout_name = args[:layout_name] || "test_layout_plate_2"
    number_of_receptacle = args[:number_of_receptacle] || 2
    plate = create_empty_plate_96(layout_name, number_of_receptacle)
    (1..3).each do |seq|
      add_metadata(plate, seq)
    end
  end

  desc "create a 96_well_plate with material for testing"
  task :create_plate_96_with_material, [:layout_name, :number_of_receptacle] => :environment do |t, args|
    layout_name = args[:layout_name] || "test_layout_plate_96"
    number_of_receptacle = args[:number_of_receptacle] || 96
    labware = create_empty_plate_96(layout_name, number_of_receptacle)
    labware.receptacles.each { |receptacle|
      receptacle.update!( material_uuid: UUID.new.generate)
    }
  end

  desc "create a 100 empty 96_well_plate for testing"
  task :create_100_empty_plate_96 => :environment do |t|
    layout_name = "test_layout_plate_96"
    number_of_receptacle = 96
    (1..100).each do
      create_empty_plate_96(layout_name, number_of_receptacle)
    end
  end

  desc "create a tube for testing"
  task :create_empty_tube => :environment do |t|
    create_empty_tube
  end

  desc "create a tube with material for testing"
  task :create_tube_with_material => :environment do |t|
    tube = create_empty_tube
    tube.receptacles.first.update!(material_uuid: UUID.new.generate)
  end

end