# See README.md for copyright details

require 'rails_helper'

RSpec.describe Layout, type: :model do
  it "should make a valid layout" do
    expect(build(:layout)).to be_valid
  end

  it "should be invalid without a name" do
    expect(build(:layout, name: nil)).to_not be_valid
  end

  it "should be invalid with a blank name" do
    expect(build(:layout, name: '')).to_not be_valid
  end
end
