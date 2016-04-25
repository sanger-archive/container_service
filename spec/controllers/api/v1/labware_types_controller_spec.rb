require 'rails_helper'

describe Api::V1::LabwareTypesController, type: :request do
  describe "GET #show" do
    it "should return a serialized labware_type instance" do
      labware_type = create(:labware_type)

      get api_v1_labware_type_path(labware_type)
      expect(response).to be_success

      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data][:id]).to eq(labware_type.id.to_s)
      expect(json[:data][:attributes][:name]).to eq(labware_type.name)
    end
  end

  describe "GET #index" do
    it "should return a list of serialized labware_type instances" do
      labware_types = create_list(:labware_type, 3)

      get api_v1_labware_types_path
      expect(response).to be_success

      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data].count).to eq(labware_types.count)

      (0...labware_types.count).each do |n|
        expect(json[:data][n][:id]).to eq(labware_types[n].id.to_s)
        expect(json[:data][n][:attributes][:name]).to eq(labware_types[n].name)
      end
    end
  end

end