# See README.md for copyright details

require 'rails_helper'

RSpec.describe Metadatum, type: :model do
  it "should make a valid metadatum" do
    expect(build(:metadatum)).to be_valid
  end

  it "should be invalid without a key" do
    expect(build(:metadatum, key: nil)).to_not be_valid
  end

  it "should be invalid with a blank key" do
    expect(build(:metadatum, key: '')).to_not be_valid
  end

  it "should be invalid without a labware" do
    expect(build(:metadatum, labware: nil)).to_not be_valid
  end

  it "should be valid with same key but different labware" do
    labware = create(:labware_with_receptacles)
    labware2 = create(:labware_with_receptacles)
    metadatum_1 = create(:metadatum, labware: labware, key: "key_1")
    
    metadatum_2 = build(:metadatum, labware: labware2, key: "key_1")

    expect(metadatum_2).to be_valid
  end

  it "should be invalid with same key and same labware" do
    labware = create(:labware_with_receptacles)
    metadatum_1 = create(:metadatum, key: 'key_1', labware: labware)
   
    metadatum_2 = build(:metadatum, key: 'key_1', labware: labware)
    expect { metadatum_2.save }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
