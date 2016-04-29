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

  describe 'POST #create' do
    let(:post_json) {
      headers = {
          'Content-Type' => 'application/json'
      }

      post api_v1_labwares_path, params: @labware_json.to_json, headers: headers
    }


    it 'should create a labware' do
      labware = build(:labware)

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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.external_id).to eq(labware.external_id)
      expect(new_labware.uuid.size).to eq(36)
      expect(new_labware.barcode).to include('TEST_XYZ_')

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
    end

    it 'should create a labware with no info' do
      labware = build(:labware)

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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.barcode).to include('TEST_')
    end

    it 'should create a labware with a given barcode' do
      labware = build(:labware)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST_BARCODE'
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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.barcode).to eq('TEST_BARCODE')
    end

    it 'should not allow duplicate barcodes' do
      create(:labware, barcode: 'TEST_BARCODE')
      labware = build(:labware)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST_BARCODE'
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

      expect { post_json }.to change { Labware.count }.by(0)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:barcode)
      expect(labware_json[:barcode]).to include('has already been taken')
    end

    it 'should create a labware with a given uuid' do
      labware = build(:labware)
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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.uuid).to eq(uuid)
    end

    it 'should not allow duplicate uuids' do
      uuid = UUID.new.generate
      create(:labware, uuid: uuid)
      labware = build(:labware)

      @labware_json = {
          data: {
              id: uuid,
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST_BARCODE'
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

      expect { post_json }.to change { Labware.count }.by(0)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:uuid)
      expect(labware_json[:uuid]).to include('has already been taken')
    end

    it 'should not allow invalid uuids' do
      labware = build(:labware)

      @labware_json = {
          data: {
              id: '12345',
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST_BARCODE'
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

      expect { post_json }.to change { Labware.count }.by(0)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:uuid)
      expect(labware_json[:uuid]).to include('is not a valid UUID')
    end

    it 'should be invalid without a labware_type' do
      labware = build(:labware)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST_BARCODE'
              }
          }
      }

      expect { post_json }.to change { Labware.count }.by(0)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:labware_type)
      expect(labware_json[:labware_type]).to include('must exist')
    end

    it 'should be invalid if labware_type does not exist' do
      labware = build(:labware)

      @labware_json = {
          data: {
              attributes: {
                  external_id: labware.external_id,
                  barcode: 'TEST_BARCODE'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: 'fake type'
                          }
                      }
                  }
              }
          }
      }

      expect { post_json }.to change { Labware.count }.by(0)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_unprocessable
      labware_json = JSON.parse(response.body, symbolize_names: true)

      expect(labware_json).to include(:labware_type)
      expect(labware_json[:labware_type]).to include('must exist')
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
      @labware = create(:labware)
      new_labware_type = create(:labware_type)

      @labware_json = {
          data: {
              attributes: {
                  external_id: @labware.external_id + '_changed',
                  barcode: @labware.barcode + '_changed'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: new_labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq(@labware.external_id + '_changed')
      expect(new_labware.barcode).to eq(@labware.barcode + '_changed')
      expect(new_labware.labware_type).to eq(new_labware_type)

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
    end

    it 'should not allow a labware_type that doesn\'t exist' do
      @labware = create(:labware)
      new_labware_type = build(:labware_type)

      @labware_json = {
          data: {
              attributes: {
                  external_id: @labware.external_id + '_change',
                  barcode: @labware.barcode + '_change'
              },
              relationships: {
                  labware_type: {
                      data: {
                          attributes: {
                              name: new_labware_type.name
                          }
                      }
                  }
              }
          }
      }

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
      expect(response).to be_unprocessable
      response_json = JSON.parse(response.body, symbolize_names: true)

      expect(response_json).to include(:labware_type)
      expect(response_json[:labware_type]).to include('must exist')

      new_labware = Labware.find(@labware.id)
      expect(new_labware).to eq(@labware)
    end

    it 'should be valid without specifying attributes' do
      @labware = create(:labware)
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
                  }
              }
          }
      }

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq(@labware.external_id)
      expect(new_labware.barcode).to eq(@labware.barcode)
      expect(new_labware.labware_type).to eq(new_labware_type)

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
    end

    it 'should be valid without specifying labware_type' do
      @labware = create(:labware)

      @labware_json = {
          data: {
              attributes: {
                  external_id: @labware.external_id + '_changed',
                  barcode: @labware.barcode + '_changed'
              }
          }
      }

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq(@labware.external_id + '_changed')
      expect(new_labware.barcode).to eq(@labware.barcode + '_changed')
      expect(new_labware.labware_type).to eq(@labware.labware_type)

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
    end

    it 'should allow external_id to be set to blank' do
      @labware = create(:labware)
      new_labware_type = create(:labware_type)

      @labware_json = {
          data: {
              attributes: {
                  external_id: ''
              }
          }
      }

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq('')

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
    end
  end
end