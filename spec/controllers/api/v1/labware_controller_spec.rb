# See README.md for copyright details

require 'rails_helper'

describe Api::V1::LayoutsController, type: :request do
  def validate_labware(labware_json, labware)
    expect(labware_json[:id]).to eq(labware.uuid)
    expect(labware_json[:attributes][:barcode]).to eq(labware.barcode)
    expect(labware_json[:attributes][:'external-id']).to eq(labware.external_id)

    labware_type_json = labware_json[:relationships][:'labware-type'][:data]
    expect(labware_type_json[:id]).to eq(labware.labware_type.id.to_s)
  end

  def validate_included_labware_type(labware_type_json, labware_type)
    expect(labware_type_json[:attributes][:name]).to eq(labware_type.name)
  end

  describe 'GET #show' do
    it 'should return a serialized layout instance' do
      labware = create(:labware)

      get api_v1_labware_path(labware.uuid)
      expect(response).to be_success

      labware_json = JSON.parse(response.body, symbolize_names: true)

      validate_labware(labware_json[:data], labware)
      validate_included_labware_type(labware_json[:included].find { |obj| obj[:id] == labware.labware_type.id.to_s and obj[:type] == 'labware-types' }, labware.labware_type)
    end
  end

  describe 'GET #index' do
    it 'should return a list of serialized layout instances' do
      labwares = create_list(:labware, 3)

      get api_v1_labwares_path
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(labwares_json[:data].count).to eq(labwares.size)

      (0...labwares.size).each do |n|
        validate_labware(labwares_json[:data][n], labwares[n])
      end
      validate_included_labware_type(labwares_json[:included].find { |obj| obj[:id] == labwares.first.labware_type.id.to_s and obj[:type] == 'labware-types' }, labwares.first.labware_type)
    end
  end

end