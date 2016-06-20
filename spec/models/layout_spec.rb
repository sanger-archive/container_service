# See README.md for copyright details

require 'rails_helper'

RSpec.describe Layout, type: :model do
  it "should make a valid layout" do
    expect(build(:layout_with_locations)).to be_valid
  end

  it "should be invalid without a name" do
    expect(build(:layout_with_locations, name: nil)).to_not be_valid
  end

  it "should be invalid with a blank name" do
    expect(build(:layout_with_locations, name: '')).to_not be_valid
  end

  it "should be invalid without number of rows" do
    expect(build(:layout_with_locations, row: nil)).to_not be_valid
  end

  it "should be invalid without number of columns" do
    expect(build(:layout_with_locations, column: nil)).to_not be_valid
  end

  it "should be invalid without any locations" do
    expect(build(:layout, locations: [])).to_not be_valid
  end

  it "should be invalid with an already existed name" do
    layout = create(:layout_with_locations)
    expect(build(:layout_with_locations, name: layout.name)).to_not be_valid
  end

end
