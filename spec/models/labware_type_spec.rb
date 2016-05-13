# See README.md for copyright details

require 'rails_helper'

RSpec.describe LabwareType, type: :model do
  it "should make a valid labware type" do
    expect(build(:labware_type)).to be_valid
  end

  it "should be invalid without a name" do
    expect(build(:labware_type, name: nil)).to_not be_valid
  end

  it "should be invalid with a blank name" do
    expect(build(:labware_type, name: '')).to_not be_valid
  end

  it "should be invalid without a layout" do
    expect(build(:labware_type, layout: nil)).to_not be_valid
  end

  it "should be invalid with an already existed name" do
    labware_type = create(:labware_type)
    expect(build(:labware_type, name: labware_type.name)).to_not be_valid
  end
end