# See README.md for copyright details

require 'rails_helper'

describe Api::V1::LabwareTypesController, type: :request do
  def validate_labware_type(labware_type_json, labware_type)
    expect(labware_type_json[:id]).to eq(labware_type.id.to_s)
    expect(labware_type_json[:attributes][:name]).to eq(labware_type.name)
    expect(labware_type_json[:relationships][:layout][:data][:id]).to eq(labware_type.layout.id.to_s)
  end

  def validate_labware_included(layout_json, layout)
    expect(layout_json[:id]).to eq(layout.id.to_s)
    expect(layout_json[:attributes][:name]).to eq(layout.name)

    expected_locations_json = layout_json[:relationships][:locations][:data]
    expect(expected_locations_json.size).to eq(layout.locations.size)
    expected_locations_json.zip(layout.locations).each do |json_location, orig_location|
      expect(json_location[:id]).to eq(orig_location.id.to_s)
    end
  end

  describe "GET #show" do
    it "should return a serialized labware_type instance" do
      labware_type = create(:labware_type)

      get api_v1_labware_type_path(labware_type)
      expect(response).to be_success

      labware_type_json = JSON.parse(response.body, symbolize_names: true)

      validate_labware_type(labware_type_json[:data], labware_type)

      layout_json = labware_type_json[:included].select { |obj| obj[:type] == 'layouts' }[0]

      validate_labware_included(layout_json, labware_type.layout)
    end
  end

  describe "GET #index" do
    it "should return a list of serialized labware_type instances" do
      labware_types = create_list(:labware_type, 3)

      get api_v1_labware_types_path
      expect(response).to be_success

      labware_types_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_types_json[:data].count).to eq(labware_types.count)

      (0...labware_types.count).each do |n|
        validate_labware_type(labware_types_json[:data][n], labware_types[n])

        layout_json = labware_types_json[:included].select { |obj|
          obj[:type] == 'layouts' and obj[:id] == labware_types_json[:data][n][:relationships][:layout][:data][:id] }[0]

        validate_labware_included(layout_json, labware_types[n].layout)
      end
    end

    it "should return the page size number of labware type instances" do
      labware_types = create_list(:labware_type, 10)
      page_size = 4
      page = 1

      get api_v1_labware_types_path, params: { "page[number]": page, "page[size]": page_size }
      expect(response).to be_success

      labware_types_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_types_json[:data].count).to eq(page_size)
    end

    it "should return the correct labware type instances with pagination" do
      labware_types = create_list(:labware_type, 10)
      page_size = 4
      page = 2
      labware_types_on_2nd_page = labware_types[4..7]

      get api_v1_labware_types_path, params: { "page[number]": page, "page[size]": page_size }
      expect(response).to be_success

      labware_types_json = JSON.parse(response.body, symbolize_names: true)

      labware_types_json_count = labware_types_json[:data].count

      expect(labware_types_json_count).to eq(page_size)

      (0...labware_types_json_count).each do |n|
        validate_labware_type(labware_types_json[:data][n], labware_types_on_2nd_page[n])
      end
    end
  end

end