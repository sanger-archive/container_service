# See README.md for copyright details

require 'rails_helper'

RSpec.describe Location, type: :model do
  it "should make a valid location" do
    expect(build(:location)).to be_valid
  end

  it "should be invalid without a name" do
    expect(build(:location, name: nil)).to_not be_valid
  end

  it "should be invalid with a blank name" do
    expect(build(:location, name: '')).to_not be_valid
  end

  it "should be invalid without a layout" do
    expect(build(:location, layout: nil)).to_not be_valid
  end

  it "should be invalid with an already existed name related to the same layout" do
    location = create(:location)
    expect(build(:location, layout: location.layout, name: location.name)).to_not be_valid
  end

  it "should be valid with same name related to different layout" do
    layout1 = create(:layout_with_locations)
    layout2 = create(:layout_with_locations)
    location_name = "A1"
    location = create(:location, layout: layout1, name: location_name)
    expect(build(:location, layout: layout2, name: location_name)).to be_valid
  end
end
