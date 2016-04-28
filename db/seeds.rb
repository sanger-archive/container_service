# See README.md for copyright details

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).


# Create the Layouts, LabwareTypes and Locations for tube, 96_well_plate and 384_well_plate
ActiveRecord::Base.transaction do
  tube_layout               = Layout.new( { name: "tube" } )
  standard_96_well_layout   = Layout.new( { name: "standard 96 well layout" } )
  standard_384_well_layout  = Layout.new( { name: "standard 384 well layout" } )

  tube_type                 = LabwareType.new( { name: "generic tube", layout: tube_layout } )
  generic_plate_96_type     = LabwareType.new( { name: "generic 96 well plate", layout: standard_96_well_layout } )
  generic_plate_384_type    = LabwareType.new( { name: "generic 384 well plate", layout: standard_384_well_layout } )

  tube_layout.locations << Location.new( { name: "A1" } )

  ('A'..'H').each do |row|
    (1..12).each do |col|
      standard_96_well_layout.locations << Location.new( { name: "#{row}#{col}" } )
    end
  end

  ('A'..'P').each do |row|
    (1..24).each do |col|
      standard_384_well_layout.locations << Location.new( { name: "#{row}#{col}" } )
    end
  end


  tube_layout.save!
  tube_type.save!
  standard_96_well_layout.save!
  generic_plate_96_type.save!
  standard_384_well_layout.save!
  generic_plate_384_type.save!
end