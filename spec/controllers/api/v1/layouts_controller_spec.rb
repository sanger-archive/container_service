# See README.md for copyright details

require 'rails_helper'

describe Api::V1::LayoutsController, type: :request do
  def validate_layout(layout_json, layout)
    expect(layout_json[:id]).to eq(layout.id.to_s)
    expect(layout_json[:attributes][:name]).to eq(layout.name)

    expected_locations_json = layout_json[:relationships][:locations][:data]
    expect(expected_locations_json.size).to eq(layout.locations.size)
    expected_locations_json.zip(layout.locations).each do |json_location, orig_location|
      expect(json_location[:id]).to eq(orig_location.id.to_s)
    end
  end

  def validate_included(locations_json, locations)
    locations_json.zip(locations).each do |json_location, orig_location|
      expect(json_location[:id]).to eq(orig_location.id.to_s)
      expect(json_location[:attributes][:name]).to eq(orig_location.name)
    end
  end

  describe "GET #show" do
    it "should return a serialized layout instance" do
      layout = create(:layout_with_locations)

      get api_v1_layout_path(layout)
      expect(response).to be_success

      layout_json = JSON.parse(response.body, symbolize_names: true)

      validate_layout(layout_json[:data], layout)

      included_locations_json = layout_json[:included].select { |obj| obj[:type] == 'locations' }

      validate_included(included_locations_json, layout.locations)
    end
  end

  describe "GET #index" do
    it "should return a list of serialized layout instances" do
      layouts = create_list(:layout_with_locations, 3)

      get api_v1_layouts_path
      expect(response).to be_success

      layouts_json = JSON.parse(response.body, symbolize_names: true)

      expect(layouts_json[:data].count).to eq(layouts.size)

      (0...layouts.size).each do |n|
        validate_layout(layouts_json[:data][n], layouts[n])

        locations_ids = layouts_json[:data][n][:relationships][:locations][:data].map { |location| location[:id]}
        included_locations_json = layouts_json[:included].select { |obj|
          obj[:type] == 'locations' && locations_ids.include?(obj[:id])
        }

        validate_included(included_locations_json, layouts[n].locations)
      end
    end

    it "should return the page size number of layout instances" do
      layouts = create_list(:layout_with_locations, 10)
      page_size = 4
      page = 1

      get api_v1_layouts_path, params: { "page[number]": page, "page[size]": page_size }
      expect(response).to be_success

      layouts_json = JSON.parse(response.body, symbolize_names: true)

      expect(layouts_json[:data].count).to eq(page_size)
    end

    it "should return the correct layout instances with pagination" do
      layouts = create_list(:layout_with_locations, 10)
      page_size = 4
      page = 2
      layouts_on_2nd_page = layouts[4..7]

      get api_v1_layouts_path, params: { "page[number]": page, "page[size]": page_size }
      expect(response).to be_success

      layouts_json = JSON.parse(response.body, symbolize_names: true)

      layouts_json_count = layouts_json[:data].count

      expect(layouts_json_count).to eq(page_size)

      (0...layouts_json_count).each do |n|
        validate_layout(layouts_json[:data][n], layouts_on_2nd_page[n])
      end
    end
  end

end