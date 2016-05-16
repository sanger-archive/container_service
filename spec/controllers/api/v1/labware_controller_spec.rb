# See README.md for copyright details

require 'rails_helper'

describe Api::V1::LabwaresController, type: :request do
  def validate_labware(labware_json, labware)
    expect(labware_json[:id]).to eq(labware.uuid)
    expect(labware_json[:attributes][:barcode]).to eq(labware.barcode)
    expect(labware_json[:attributes][:'external-id']).to eq(labware.external_id)

    labware_type_json = labware_json[:relationships][:'labware-type'][:data]
    expect(labware_type_json[:id]).to eq(labware.labware_type.id.to_s)

    receptacles_json = labware_json[:relationships][:receptacles][:data]
    expect(receptacles_json.size).to eq(labware.receptacles.size)
  end

  def validate_included_labware_type(labware_type_json, labware_type)
    expect(labware_type_json[:attributes][:name]).to eq(labware_type.name)
  end

  def validate_included_receptacles(receptacles_json, receptacles)
    receptacles_json.zip(receptacles).each { |receptacle_json, receptacle| 
      expect(receptacle_json[:relationships][:location][:data][:id]).to eq(receptacle.location.id.to_s)
      expect(receptacle_json[:attributes][:'material-uuid']).to eq(receptacle.material_uuid)
    }
  end

  def validate_included_locations(locations_json, locations)
    locations_json.zip(locations).each { |location_json, location| 
      expect(location_json[:id]).to eq(location.id.to_s)
      expect(location_json[:attributes][:name]).to eq(location.name)
    }
  end

  def validate_labware_with_metadata(labware_json_data, labware)
    (0...labware.metadata.count).each do |n|
      expect(labware_json_data[:relationships][:metadata][:data][n][:id]).to eq(labware.metadata[n].id.to_s)
    end
  end

  def validate_included_metadata(metadata_json, metadata)
    (0...metadata.count).each do |n|
      metadatum_json = metadata_json.select { |obj| obj[:id] == metadata[n].id.to_s }[0]
      expect(metadatum_json[:attributes][:key]).to eq(metadata[n].key)
      expect(metadatum_json[:attributes][:value]).to eq(metadata[n].value)
    end
  end

  let(:check_response_is_same) {
    post_response = response
    get api_v1_labware_path(Labware.last.uuid)
    get_response = response
    expect(post_response.body).to eq(get_response.body)
  }

  describe 'GET #show' do
    it 'should return a serialized labware instance' do
      labware = create(:labware_with_receptacles_with_material)

      get api_v1_labware_path(labware.uuid)
      expect(response).to be_success

      labware_json = JSON.parse(response.body, symbolize_names: true)

      validate_labware(labware_json[:data], labware)
      validate_included_labware_type(labware_json[:included].find { |obj| obj[:id] == labware.labware_type.id.to_s and obj[:type] == 'labware-types' }, labware.labware_type)
      validate_included_receptacles(labware_json[:included].select { |obj| obj[:type] == 'receptacles' }, labware.receptacles)
      validate_included_locations(labware_json[:included].select { |obj| obj[:type] == 'locations' }, labware.receptacles.map { |r| r.location })
    end

    it 'should return a serialized labware instance with metadata' do
      labware = create(:labware_with_receptacles_with_metadata)

      get api_v1_labware_path(labware.uuid)
      expect(response).to be_success

      labware_json = JSON.parse(response.body, symbolize_names: true)

      validate_labware(labware_json[:data], labware)
      validate_labware_with_metadata(labware_json[:data], labware)
      validate_included_metadata(labware_json[:included].select { |obj| obj[:type] == 'metadata' }, labware.metadata)
    end
  end

  describe 'GET #index' do
    it 'should return a list of serialized labware instances' do
      labwares = create_list(:labware_with_receptacles_with_material, 3)

      get api_v1_labwares_path
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(labwares_json[:data].count).to eq(labwares.size)

      (0...labwares.size).each do |n|
        validate_labware(labwares_json[:data][n], labwares[n])
      end
      validate_included_labware_type(labwares_json[:included].find { |obj| obj[:id] == labwares.first.labware_type.id.to_s and obj[:type] == 'labware-types' }, labwares.first.labware_type)
      validate_included_receptacles(labwares_json[:included].select { |obj| obj[:type] == 'receptacles' }, labwares.map {|labware| labware.receptacles }.flatten)
      validate_included_locations(labwares_json[:included].select { |obj| obj[:type] == 'locations' }, labwares.map {|labware| labware.receptacles.map { |r| r.location }}.flatten)
    end

    it 'should return a list of serialized labware instances with metadata' do
      labwares = create_list(:labware_with_receptacles_with_metadata, 3)

      get api_v1_labwares_path
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(labwares_json[:data].count).to eq(labwares.size)

      (0...labwares.size).each do |n|
        labware_json = labwares_json[:data][n]
        validate_labware_with_metadata(labware_json, labwares[n])
        validate_included_metadata(labwares_json[:included].select { |obj| obj[:type] == 'metadata' }, labwares[n].metadata)
      end
    end

    it "should return the page size number of labware instances" do
      labwares = create_list(:labware_with_receptacles_with_metadata, 10)
      page_size = 4
      page = 1

      get api_v1_labwares_path, params: { "page[number]": page, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(labwares_json[:data].count).to eq(page_size)
    end

    it "should return the correct labware instances with pagination" do
      labwares = create_list(:labware_with_receptacles_with_metadata, 10)
      page_size = 4
      page = 2
      labwares_on_2nd_page = labwares[4..7]

      get api_v1_labwares_path, params: { "page[number]": page, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      labwares_json_count = labwares_json[:data].count

      expect(labwares_json_count).to eq(page_size)

      (0...labwares_json_count).each do |n|
        validate_labware(labwares_json[:data][n], labwares_on_2nd_page[n])
      end
    end

    it "should return the correct labware instances when searching by type" do
      labware_type = create(:labware_type)
      labware_type2 = create(:labware_type)
      labwares = create_list(:labware_with_receptacles_with_metadata, 15, labware_type: labware_type)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15, labware_type: labware_type2)
      page_size = 100

      get api_v1_labwares_path, params: { labware_type: labware_type.name, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(labwares.size + labwares2.size)
      expect(labwares_json[:data].size).to eq(labwares.size)
      validate_included_labware_type(labwares_json[:included].find { |obj| obj[:id] == labware_type.id.to_s and obj[:type] == 'labware-types' }, labware_type)
    end

    it "should not return any labware instance when searching by not correct type" do
      labware_type = create(:labware_type)
      labware_type2 = create(:labware_type)
      labwares = create_list(:labware_with_receptacles_with_metadata, 15, labware_type: labware_type)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15, labware_type: labware_type2)
      page_size = 100

      get api_v1_labwares_path, params: { labware_type: labware_type.name + "_not_matching", "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(labwares.size + labwares2.size)
      expect(labwares_json[:data].size).to eq(0)
    end

    it 'should return the correct labware instances when searching by barcode' do
      barcode = 'TEST-BARCODE-00001'
      labwares = create_list(:labware_with_receptacles_with_metadata, 1, barcode: barcode)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { barcode: barcode, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(labwares.size + labwares2.size)
      expect(labwares_json[:data].size).to eq(labwares.size)
      expect(labwares_json[:data][0][:attributes][:barcode]).to eq(barcode)
    end

    it "should not return any labware instance when searching by not correct barcode" do
      barcode = 'TEST-BARCODE-00001'
      barcode_not_matching = '1234'
      labwares = create_list(:labware_with_receptacles_with_metadata, 1, barcode: barcode)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { barcode: barcode_not_matching, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(labwares.size + labwares2.size)
      expect(labwares_json[:data].size).to eq(0)
    end

    it "should return the correct labware instances when searching by external id" do
      external_id = "external_id"
      labwares = create_list(:labware_with_receptacles_with_metadata, 1, external_id: external_id)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { external_id: external_id, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(labwares.size + labwares2.size)
      expect(labwares_json[:data].size).to eq(labwares.size)
      expect(labwares_json[:data][0][:attributes][:"external-id"]).to eq(external_id)
    end

    it "should not return any labware instance when searching by not correct external id" do
      external_id = "external_id"
      external_id_not_matching = "1234_external_id"
      labwares = create_list(:labware_with_receptacles_with_metadata, 1, external_id: external_id)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { external_id: external_id_not_matching, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(labwares.size + labwares2.size)
      expect(labwares_json[:data].size).to eq(0)
    end

    it "should return the correct labware instances when searching by type and barcode and external id" do
      labware_type = create(:labware_type)
      barcode = "test_barcode test"
      external_id = "external_id"
      labware = create(:labware_with_receptacles_with_metadata,
        external_id: external_id, labware_type: labware_type, barcode: barcode)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { external_id: external_id, labware_type: labware_type.name, barcode: barcode, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(1 + labwares2.size)
      expect(labwares_json[:data].size).to eq(1)
      validate_included_labware_type(labwares_json[:included].find { |obj| obj[:id] == labware_type.id.to_s and obj[:type] == 'labware-types' }, labware_type)
      expect(labwares_json[:data][0][:attributes][:barcode]).to eq(barcode)
      expect(labwares_json[:data][0][:attributes][:"external-id"]).to eq(external_id)
    end

    it "should return all labware instances that's creation date less than the given date when searching by before" do
      before_creation_date = DateTime.new(2006,1,1)
      (2001..2010).each do |year|
        create(:labware_with_receptacles_with_metadata, created_at: DateTime.new(year,1,1))
      end
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { created_before: before_creation_date, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(25)
      expect(labwares_json[:data].size).to eq(6)
      labwares_json[:data].each do |labware_json_data|
        expect(labware_json_data[:attributes][:"created-at"].to_datetime).to be <= before_creation_date
      end
    end

    it "should not return any labware instances that's creation date greater than the given date when searching by before" do
      before_creation_date = DateTime.new(1986,5,12)
      (2001..2010).each do |year|
        create(:labware_with_receptacles_with_metadata, created_at: DateTime.new(year,1,1))
      end
      page_size = 100

      get api_v1_labwares_path, params: { created_before: before_creation_date, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(10)
      expect(labwares_json[:data].size).to eq(0)
    end

    it "should return all labware instances that's creation date greater than the given date when searching by after" do
      early_creation_date = DateTime.new(1999,1,1)
      after_creation_date = DateTime.new(2006,2,1)
      (2001..2010).each do |year|
        create(:labware_with_receptacles_with_metadata, created_at: DateTime.new(year,1,1))
      end
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15, created_at: early_creation_date)
      page_size = 100

      get api_v1_labwares_path, params: { created_after: after_creation_date, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(25)
      expect(labwares_json[:data].size).to eq(4)
      labwares_json[:data].each do |labware_json_data|
        expect(labware_json_data[:attributes][:"created-at"].to_datetime).to be >= after_creation_date
      end
    end

    it "should not return any labware instances that's creation date less than the given date when searching by after" do
      after_creation_date = DateTime.new(2100,5,12)
      (2001..2010).each do |year|
        create(:labware_with_receptacles_with_metadata, created_at: DateTime.new(year,1,1))
      end
      page_size = 100

      get api_v1_labwares_path, params: { created_after: after_creation_date, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(10)
      expect(labwares_json[:data].size).to eq(0)
    end

    it "should return all labware instances that's creation date between the given dates when searching by before and after" do
      before_creation_date = DateTime.new(2006,9,1)
      after_creation_date =  DateTime.new(2003,2,1)
      (2001..2010).each do |year|
        create(:labware_with_receptacles_with_metadata, created_at: DateTime.new(year,1,1))
      end
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { created_after: after_creation_date, created_before: before_creation_date, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(25)
      expect(labwares_json[:data].size).to eq(3)
      labwares_json[:data].each do |labware_json_data|
        expect(labware_json_data[:attributes][:"created-at"].to_datetime).to be <= before_creation_date
        expect(labware_json_data[:attributes][:"created-at"].to_datetime).to be >= after_creation_date
      end
    end

    it "should return the correct labware instances when searching by barcode prefix" do
      barcode_prefix = "ABCD"
      labware = create(:labware_with_receptacles_with_metadata, barcode_prefix: barcode_prefix)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { barcode_prefix: barcode_prefix, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(1 + labwares2.size)
      expect(labwares_json[:data].size).to eq(1)
      expect(labwares_json[:data][0][:attributes][:barcode]).to start_with(barcode_prefix)
    end

    it "should not return any labware instance when searching by not matching barcode_prefix prefix" do
      barcode_prefix = "ABCD"
      barcode_prefix_not_matching = "abc1"
      labware = create(:labware_with_receptacles_with_metadata, barcode_prefix: barcode_prefix)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { barcode_prefix: barcode_prefix_not_matching, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(1 + labwares2.size)
      expect(labwares_json[:data].size).to eq(0)
    end

    it "should return the correct labware instances when searching by barcode info" do
      barcode_info = "ABCD"
      labware = create(:labware_with_receptacles_with_metadata, barcode_info: barcode_info)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { barcode_info: barcode_info, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(1 + labwares2.size)
      expect(labwares_json[:data].size).to eq(1)
      expect(labwares_json[:data][0][:attributes][:barcode]).to include(barcode_info)
    end

    it "should not return any labware instance when searching by not matching barcode_info info" do
      barcode_info = "ABCD"
      barcode_info_not_matching = "abc1"
      labware = create(:labware_with_receptacles_with_metadata, barcode_info: barcode_info)
      labwares2 =create_list(:labware_with_receptacles_with_metadata, 15)
      page_size = 100

      get api_v1_labwares_path, params: { barcode_info: barcode_info_not_matching, "page[size]": page_size }
      expect(response).to be_success

      labwares_json = JSON.parse(response.body, symbolize_names: true)

      expect(Labware.all.size).to eq(1 + labwares2.size)
      expect(labwares_json[:data].size).to eq(0)
    end
  end

  describe 'POST #create' do
    let(:post_json) {
      headers = {
          'Content-Type' => 'application/json'
      }

      post api_v1_labwares_path, params: @labware_json.to_json, headers: headers
    }

    it 'should create a empty labware' do
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST',
                  barcode_info: 'XYZ'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(1)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Receptacle.count }.by(labware.receptacles.size)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.external_id).to eq(labware.external_id)
      expect(new_labware.uuid.size).to eq(36)
      expect(new_labware.barcode).to include('TEST-XYZ-')
      expect(new_labware.metadata).to be_empty

      check_response_is_same
    end

    it 'should create a labware with no info' do
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(1)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.barcode).to include('TEST-')
    end

    it 'should create a labware with a given barcode' do
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST-BARCODE'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(1)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.barcode).to eq('TEST-BARCODE')
    end

    it 'should not allow duplicate barcodes' do
      create(:labware_with_receptacles, barcode: 'TEST-BARCODE')
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST-BARCODE'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(0)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:barcode)
      expect(labware_json[:barcode]).to include('has already been taken')
    end

    it 'should create a labware with a given uuid' do
      labware = build(:labware_with_receptacles)
      uuid = UUID.new.generate

      @labware_json = {
          data: {
              id: uuid,
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(1)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.uuid).to eq(uuid)
    end

    it 'should not allow duplicate uuids' do
      uuid = UUID.new.generate
      create(:labware_with_receptacles, uuid: uuid)
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              id: uuid,
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST-BARCODE'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(0)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:uuid)
      expect(labware_json[:uuid]).to include('has already been taken')
    end

    it 'should not allow invalid uuids' do
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              id: '12345',
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST-BARCODE'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(0)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:uuid)
      expect(labware_json[:uuid]).to include('is not a valid UUID')
    end

    it 'should be invalid without a labware_type' do
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST-BARCODE'
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(0)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:labware_type)
      expect(labware_json[:labware_type]).to include('must exist')
    end

    it 'should be invalid if labware_type does not exist' do
      labware = build(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST-BARCODE'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: 'fake type'
                          }
                      }
                  },
                  receptacles: {
                      data: labware.receptacles.map { |receptacle| {
                          attributes: {
                              material_uuid: receptacle.material_uuid
                          },
                          relationships: {
                              location: {
                                  data: {
                                      attributes: {
                                          name: receptacle.location.name
                                      }
                                  }
                              }
                          }
                      }}
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(0)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:labware_type)
      expect(labware_json[:labware_type]).to include('must exist')
    end

    it 'should create a labware with materials in it' do
      labware = build(:labware_with_receptacles_with_material)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST',
                  barcode_info: 'XYZ'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  },
                  receptacles: {
                    data: labware.receptacles.map { |receptacle| { 
                      attributes: {
                        material_uuid: receptacle.material_uuid
                      },
                      relationships: {
                        location: {
                          data: {
                            attributes: {
                              name: receptacle.location.name
                            }
                          }
                        }
                      }
                    }}
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(1)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Receptacle.count }.by(labware.receptacles.size)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.external_id).to eq(labware.external_id)
      expect(new_labware.uuid.size).to eq(36)
      expect(new_labware.barcode).to include('TEST-XYZ-')

      new_labware.receptacles.zip(labware.receptacles) { |new_receptacle, receptacle_orig|
        expect(new_receptacle.material_uuid).to eq(receptacle_orig.material_uuid)
        expect(new_receptacle.location).to eq(receptacle_orig.location)
      }

      check_response_is_same
    end

    it 'should create a labware with 1 material in it' do
      labware = build(:labware_with_receptacles)
      labware.receptacles.first.material_uuid = UUID.new.generate

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST',
                  barcode_info: 'XYZ'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  },
                  receptacles: {
                    data: [{
                      attributes: {
                        material_uuid: labware.receptacles.first.material_uuid
                      },
                      relationships: {
                        location: {
                          data: {
                            attributes: {
                              name: labware.receptacles.first.location.name
                            }
                          }
                        }
                      }
                    }]
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(1)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Receptacle.count }.by(labware.receptacles.size)
                          .and  change { Metadatum.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.external_id).to eq(labware.external_id)
      expect(new_labware.uuid.size).to eq(36)
      expect(new_labware.barcode).to include('TEST-XYZ-')

      new_labware.receptacles.zip(labware.receptacles) { |new_receptacle, receptacle_orig|
        expect(new_receptacle.material_uuid).to eq(receptacle_orig.material_uuid)
        expect(new_receptacle.location).to eq(receptacle_orig.location)
      }

      check_response_is_same
    end

    it 'should create a empty labware with metadata' do
      labware = build(:labware_with_receptacles_with_metadata)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST',
                  barcode_info: 'XYZ'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  },
                  metadata: {
                      data: labware.metadata.map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(1)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Receptacle.count }.by(labware.receptacles.size)
                          .and  change { Metadatum.count }.by(3)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.metadata.size).to eq(labware.metadata.size)
      new_labware.metadata.zip(labware.metadata).each do |new_metadatum, metadatum|
        expect(new_metadatum.key).to eq(metadatum.key)
        expect(new_metadatum.value).to eq(metadatum.value)
      end

      check_response_is_same
    end

    it 'should return the created instance with metadata' do
      labware = build(:labware_with_receptacles_with_metadata)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST',
                  barcode_info: 'XYZ'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  },
                  metadata: {
                      data: labware.metadata.map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      post_json

      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json[:data][:relationships][:metadata][:data].size).to eq(labware.metadata.size)

      expect(labware_json[:included].select { |obj| obj[:type] == 'metadata' }.size).to eq(labware.metadata.size)
      labware_json[:included].select { |obj| obj[:type] == 'metadata' }.zip(labware.metadata).each do |included_metadata, metadata|
        expect(included_metadata[:attributes][:key]).to eq(metadata.key)
        expect(included_metadata[:attributes][:value]).to eq(metadata.value)
      end
    end

    it 'should fail if given invalid metadata' do
      labware = build(:labware_with_receptacles_with_metadata)
      labware.metadata.last.key = nil

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode_prefix: 'TEST',
                  barcode_info: 'XYZ'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: labware.labware_type.name
                          }
                      }
                  },
                  metadata: {
                      data: labware.metadata.map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      expect { post_json }.to   change { Labware.count }.by(0)
                          .and  change { LabwareType.count }.by(0)
                          .and  change { Receptacle.count }.by(0)
                          .and  change { Metadatum.count }.by(0)

      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:'metadata.key')
      expect(labware_json[:'metadata.key']).to include('can\'t be blank')
    end
  end

  describe 'PUT #update' do
    let(:update_labware) {
      headers = {
          'Content-Type' => 'application/json'
      }

      put api_v1_labware_path(@labware.uuid), params: @labware_json.to_json, headers: headers
    }

    it 'should update the labware' do
      @labware = create(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: @labware.external_id + '_changed',
                  barcode: @labware.barcode + '_changed'
              }
          }
      }

      expect { update_labware  }.to  change { Labware.count }.by(0)
                                .and change { LabwareType.count }.by(0)
                                .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq(@labware.external_id + '_changed')
      expect(new_labware.barcode).to eq(@labware.barcode + '_changed')

      check_response_is_same
    end

    it "should not be able to change the labware type" do
      @labware = create(:labware_with_receptacles)
      new_labware_type = create(:labware_type)

      @labware_json = {
          data: {
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: new_labware_type.name
                          }
                      }
                  },
                  receptacles: {
                      data: @labware.receptacles.map { |receptacle| {
                          attributes: {
                              material_uuid: receptacle.material_uuid
                          },
                          relationships: {
                              location: {
                                  data: {
                                      attributes: {
                                          name: receptacle.location.name
                                      }
                                  }
                              }
                          }
                      }}
                  }
              }
          }
      }

      expect { update_labware  }.to   change { Labware.count }.by(0)
                                .and  change { LabwareType.count }.by(0)
                                .and  change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:labware_type)
      expect(response_json[:labware_type]).to include("can't be changed")
    end

    it "should not be able to change the labware type to a type that doesn't exist" do
      @labware = create(:labware_with_receptacles)

      @labware_json = {
          data: {
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: 'fake_labware_type'
                          }
                      }
                  },
                  receptacles: {
                      data: @labware.receptacles.map { |receptacle| {
                          attributes: {
                              material_uuid: receptacle.material_uuid
                          },
                          relationships: {
                              location: {
                                  data: {
                                      attributes: {
                                          name: receptacle.location.name
                                      }
                                  }
                              }
                          }
                      }}
                  }
              }
          }
      }

      expect { update_labware  }.to   change { Labware.count }.by(0)
                                          .and  change { LabwareType.count }.by(0)
                                                    .and  change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable

      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:labware_type)
      expect(response_json[:labware_type]).to include("can't be changed")
    end

    it 'should be valid without specifying labware_type' do
      @labware = create(:labware_with_receptacles)

      @labware_json = {
          data: {
              attributes: {
                  external_id: @labware.external_id + '_changed',
                  barcode: @labware.barcode + '_changed'
              }
          }
      }

      expect { update_labware  }.to   change { Labware.count }.by(0)
                                .and  change { LabwareType.count }.by(0)
                                .and  change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq(@labware.external_id + '_changed')
      expect(new_labware.barcode).to eq(@labware.barcode + '_changed')
      expect(new_labware.labware_type).to eq(@labware.labware_type)

      check_response_is_same
    end

    it 'should allow external_id to be set to blank' do
      @labware = create(:labware_with_receptacles)
      new_labware_type = create(:labware_type)

      @labware_json = {
          data: {
              attributes: {
                  external_id: ''
              }
          }
      }

      expect { update_labware }.to  change { Labware.count }.by(0)
                               .and change { LabwareType.count }.by(0)
                               .and change { Receptacle.count }.by(0)
                               .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq('')

      check_response_is_same
    end

    it 'should be able to add a material_uuid to a receptacle' do
      @labware = create(:labware_with_receptacles)
      @labware.receptacles.first.material_uuid = UUID.new.generate

      @labware_json = {
        data: {
          relationships: {
            receptacles: {
              data: [
                {
                  attributes: {
                    material_uuid: @labware.receptacles.first.material_uuid
                  },
                  relationships: {
                    location: {
                      data: {
                        attributes: {
                          name: @labware.receptacles.first.location.name
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      }

      expect { update_labware }.to  change { Labware.count }.by(0)
                               .and change { LabwareType.count }.by(0)
                               .and change { Receptacle.count }.by(0)
                               .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      new_labware.receptacles.zip(@labware.receptacles).each { |new_receptacle, receptacle| 
        expect(new_receptacle.material_uuid).to eq(receptacle.material_uuid)
        expect(new_receptacle.location).to eq(receptacle.location)
      }
    end

    it 'should be able to clear the material_uuid from a receptacle' do
      @labware = create(:labware_with_receptacles_with_material)
      @labware.receptacles.first.material_uuid = nil

      @labware_json = {
        data: {
          relationships: {
            receptacles: {
              data: [
                {
                  attributes: {
                    material_uuid: @labware.receptacles.first.material_uuid
                  },
                  relationships: {
                    location: {
                      data: {
                        attributes: {
                          name: @labware.receptacles.first.location.name
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      }

      expect { update_labware }.to  change { Labware.count }.by(0)
                               .and change { LabwareType.count }.by(0)
                               .and change { Receptacle.count }.by(0)
                               .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      new_labware.receptacles.zip(@labware.receptacles).each { |new_receptacle, receptacle| 
        expect(new_receptacle.material_uuid).to eq(receptacle.material_uuid)
        expect(new_receptacle.location).to eq(receptacle.location)
      }
    end

    it 'should be able to change the material_uuid in a receptacle' do
      @labware = create(:labware_with_receptacles_with_material)
      @labware.receptacles.first.material_uuid = UUID.new.generate

      @labware_json = {
        data: {
          relationships: {
            receptacles: {
              data: [
                {
                  attributes: {
                    material_uuid: @labware.receptacles.first.material_uuid
                  },
                  relationships: {
                    location: {
                      data: {
                        attributes: {
                          name: @labware.receptacles.first.location.name
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      }

      expect { update_labware }.to  change { Labware.count }.by(0)
                               .and change { LabwareType.count }.by(0)
                               .and change { Receptacle.count }.by(0)
                               .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      new_labware.receptacles.zip(@labware.receptacles).each { |new_receptacle, receptacle| 
        expect(new_receptacle.material_uuid).to eq(receptacle.material_uuid)
        expect(new_receptacle.location).to eq(receptacle.location)
      }
    end

    it 'should update the existing labware metadata' do
      @labware = create(:labware_with_receptacles_with_metadata)
      changed_value = "_changed"

      @labware_json = {
          data: {
              relationships: {
                  metadata: {
                      data: @labware.metadata.map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value + changed_value}} }
                  }
              }
          }
      }

      expect { update_labware  }.to  change { Labware.count }.by(0)
                                .and change { LabwareType.count }.by(0)
                                .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json[:data][:relationships][:metadata][:data].size).to eq(@labware.metadata.size)
      labware_json[:data][:relationships][:metadata][:data].zip(@labware.metadata) do |new_metadata, old_metadata|
        expect(new_metadata[:id]).to eq(old_metadata.id.to_s)
      end
      expect(labware_json[:included].select { |obj| obj[:type] == "metadata" }.size).to eq(@labware.metadata.size)
      @labware.metadata.each do |metadatum|
        metadatum_json = labware_json[:included].find { |obj| obj[:type] == "metadata" and obj[:id] == metadatum.id.to_s }
        expect(metadatum_json[:attributes][:key]).to eq(metadatum.key)
        expect(metadatum_json[:attributes][:value]).to eq(metadatum.value + changed_value)
      end

      new_labware = Labware.find(@labware.id)
      new_labware.metadata.zip(@labware.metadata).each do |new_metadata, old_metadata|
        expect(new_metadata.id).to eq(old_metadata.id)
        expect(new_metadata.key).to eq(old_metadata.key)
        expect(new_metadata.value).to eq(old_metadata.value + changed_value)
      end
    end

    it 'should add additional metadata to the labware' do
      @labware = create(:labware_with_receptacles_with_metadata)
      new_metadatum = build(:metadatum)

      @labware_json = {
          data: {
              relationships: {
                  metadata: {
                      data: (@labware.metadata + [new_metadatum]).map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      expect { update_labware  }.to  change { Labware.count }.by(0)
                                .and change { LabwareType.count }.by(0)
                                .and change { Metadatum.count }.by(1)
      expect(response).to be_success

      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json[:data][:relationships][:metadata][:data].size).to eq(@labware.metadata.size + 1)
      labware_json[:data][:relationships][:metadata][:data][0...@labware.metadata.size].zip(@labware.metadata) do |new_metadata, old_metadata|
        expect(new_metadata[:id]).to eq(old_metadata.id.to_s)
      end

      expect(labware_json[:included].select { |obj| obj[:type] == "metadata" }.size).to eq(@labware.metadata.size + 1)
      (@labware.metadata).each do |metadatum|
        metadatum_json = labware_json[:included].find { |obj| obj[:type] == "metadata" and obj[:id] == metadatum.id.to_s }
        expect(metadatum_json[:attributes][:key]).to eq(metadatum.key)
        expect(metadatum_json[:attributes][:value]).to eq(metadatum.value)
      end
      new_metadatum_json = labware_json[:included].last
      expect(new_metadatum_json[:attributes][:key]).to eq(new_metadatum.key)
      expect(new_metadatum_json[:attributes][:value]).to eq(new_metadatum.value)

      new_labware = Labware.find(@labware.id)
      new_labware.metadata[0...@labware.metadata.size].zip(@labware.metadata).each do |new_metadata, old_metadata|
        expect(new_metadata.id).to eq(old_metadata.id)
        expect(new_metadata.key).to eq(old_metadata.key)
        expect(new_metadata.value).to eq(old_metadata.value)
      end

      expect(Metadatum.last.key).to eq(new_metadatum.key)
      expect(Metadatum.last.value).to eq(new_metadatum.value)
    end

    it 'should keep all old metadata if none are provided' do
      @labware = create(:labware_with_receptacles_with_metadata)

      @labware_json = {
          data: {
              attributes: {},
              relationships: {}
          }
      }

      expect { update_labware  }.to  change { Labware.count }.by(0)
                                .and change { LabwareType.count }.by(0)
                                .and change { Metadatum.count }.by(0)
      expect(response).to be_success

      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json[:data][:relationships][:metadata][:data].size).to eq(@labware.metadata.size)
      expect(Labware.find(@labware.id).metadata).to eq(@labware.metadata)
    end

    it 'should not alter the database if the request is unsuccessful' do
      @labware = create(:labware_with_receptacles_with_metadata)
      new_metadatum = build(:metadatum)
      new_metadatum.key = nil

      @labware_json = {
          data: {
              attributes: {
                  external_id: @labware.external_id + '_changed',
                  barcode: @labware.barcode + '_changed'
              },
              relationships: {
                  receptacles: {
                    data: [
                      {
                        attributes: {
                          material_uuid: @labware.receptacles.first.material_uuid
                        },
                        relationships: {
                          location: {
                            data: {
                              attributes: {
                                name: @labware.receptacles.first.location.name
                              }
                            }
                          }
                        }
                      }
                    ]
                  },
                  metadata: {
                      data: (@labware.metadata + [new_metadatum]).map { |metadatum| {attributes: {key: metadatum.key, value: metadatum.value}} }
                  }
              }
          }
      }

      expect { update_labware  }.to  change { Labware.count }.by(0)
                                .and change { LabwareType.count }.by(0)
                                .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable

      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.find(@labware.id)
      expect(new_labware.external_id).to eq(@labware.external_id)
      expect(new_labware.barcode).to eq(@labware.barcode)

      expect(new_labware.metadata.first.value).to eq(@labware.metadata.first.value)
      expect(new_labware.metadata.size).to eq(@labware.metadata.size)
      new_labware.metadata.zip(@labware.metadata).each { |new_metadatum, metadatum|
        expect(new_metadatum.key).to eq(metadatum.key)
        expect(new_metadatum.value).to eq(metadatum.value)
      }

      expect(labware_json).to include(:'metadata.key')
      expect(labware_json[:'metadata.key']).to include("can't be blank")
    end

    it 'should not allow filling a location that doesn\'t exist' do
      @labware = create(:labware_with_receptacles_with_metadata)

      @labware_json = {
          data: {
              relationships: {
                  receptacles: {
                      data: [
                          {
                              attributes: {
                                  material_uuid: @labware.receptacles.first.material_uuid
                              },
                              relationships: {
                                  location: {
                                      data: {
                                          attributes: {
                                              name: 'fake location'
                                          }
                                      }
                                  }
                              }
                          }
                      ]
                  }
              }
          }
      }

      expect { update_labware  }.to  change { Labware.count }.by(0)
                                         .and change { LabwareType.count }.by(0)
                                                  .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable

      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:'receptacles.location')
      expect(labware_json[:'receptacles.location']).to include('must exist')
    end

    it 'should not allow filling a location that\'s not in this type' do
      @labware = create(:labware_with_receptacles_with_metadata)
      location = create(:location)

      @labware_json = {
          data: {
              relationships: {
                  receptacles: {
                      data: [
                          {
                              attributes: {
                                  material_uuid: @labware.receptacles.first.material_uuid
                              },
                              relationships: {
                                  location: {
                                      data: {
                                          attributes: {
                                              name: location.name
                                          }
                                      }
                                  }
                              }
                          }
                      ]
                  }
              }
          }
      }

      expect { update_labware  }.to  change { Labware.count }.by(0)
                                         .and change { LabwareType.count }.by(0)
                                                  .and change { Metadatum.count }.by(0)
      expect(response).to be_unprocessable

      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:'receptacles.location')
      expect(labware_json[:'receptacles.location']).to include('must correspond to layout of this labware type')
    end
  end
end