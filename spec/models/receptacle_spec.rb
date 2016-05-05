# See README.md for copyright details

require 'rails_helper'
require 'uuid'

RSpec.describe Receptacle, type: :model do
  it "should make a valid receptacle" do
    labware = build(:labware_with_receptacles)

    expect(labware.receptacles.first).to be_valid
  end

  it "should be valid with a valid material_uuid" do
    labware = build(:labware_with_receptacles)
    receptacle = labware.receptacles.first
    receptacle.material_uuid = UUID.new.generate

    expect(receptacle).to be_valid
  end

  it "should be invalid without a location" do
    receptacle = build(:receptacle)
    receptacle.location = nil
    expect(receptacle).to_not be_valid
  end

  it "should be invalid without a labware" do
    expect(build(:receptacle, labware: nil)).to_not be_valid
  end

  it "should be invalid with an invalid material_uuid" do
    labware = build(:labware_with_receptacles)
    receptacle = labware.receptacles.first
    receptacle.material_uuid = 'not valid uuid'

    expect(receptacle).to_not be_valid
  end

  it "should be invalid with 2 receptacles sharing the same location in the same labware" do
    labware   = create(:labware_with_receptacles)

    receptacle_1 = labware.receptacles[0]
    receptacle_2 = labware.receptacles[1]
    receptacle_2.location = receptacle_1.location
    
    expect(receptacle_2).to_not be_valid
  end

  it "should be valid with 2 receptacles having the same location value in different labwares" do
    labware   = create(:labware_with_receptacles)
    labware2  = create(:labware_with_receptacles, labware_type: labware.labware_type)
    
    receptacle_1 = labware.receptacles[0]
    receptacle_2 = labware2.receptacles[0]

    expect(receptacle_1.location).to eq(receptacle_2.location)
    expect(receptacle_1.labware).to_not eq(receptacle_2.labware)
    expect(receptacle_2).to be_valid
  end

  it "should be valid with 2 receptacles with different location values in the same labware" do
    labware   = create(:labware_with_receptacles)
    
    receptacle_1 = labware.receptacles[0]
    receptacle_2 = labware.receptacles[1]

    expect(receptacle_1.labware).to eq(receptacle_2.labware)
    expect(receptacle_1.location).to_not eq(receptacle_2.location)
    expect(receptacle_1).to be_valid  
  end
end
