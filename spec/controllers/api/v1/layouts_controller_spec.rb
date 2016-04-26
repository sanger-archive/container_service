# See README.md for copyright details

require 'rails_helper'

describe Api::V1::LayoutsController, type: :request do
  def validate_layout(layout_json, layout)
    expect(layout_json[:id]).to eq(layout.id.to_s)
    expect(layout_json[:attributes][:name]).to eq(layout.name)
  end

  describe "GET #show" do
    it "should return a serialized layout instance" do
      layout = create(:layout)

      get api_v1_layout_path(layout)
      expect(response).to be_success

      layout_json = JSON.parse(response.body, symbolize_names: true)

      validate_layout(layout_json[:data], layout)
    end
  end

  describe "GET #index" do
    it "should return a list of serialized layout instances" do
      layouts = create_list(:layout, 3)

      get api_v1_layouts_path
      expect(response).to be_success

      layouts_json = JSON.parse(response.body, symbolize_names: true)

      expect(layouts_json[:data].count).to eq(layouts.count)

      (0...layouts.count).each do |n|
        validate_layout(layouts_json[:data][n], layouts[n])
      end
    end
  end

end