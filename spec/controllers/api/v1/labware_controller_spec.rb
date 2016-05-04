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

  describe 'GET #show' do
    it 'should return a serialized layout instance' do
      labware = create(:labware_with_receptacles_with_material)

      get api_v1_labware_path(labware.uuid)
      expect(response).to be_success

      labware_json = JSON.parse(response.body, symbolize_names: true)

      validate_labware(labware_json[:data], labware)
      validate_included_labware_type(labware_json[:included].find { |obj| obj[:id] == labware.labware_type.id.to_s and obj[:type] == 'labware-types' }, labware.labware_type)
      validate_included_receptacles(labware_json[:included].select { |obj| obj[:type] == 'receptacles' }, labware.receptacles)
      validate_included_locations(labware_json[:included].select { |obj| obj[:type] == 'locations' }, labware.receptacles.map { |r| r.location })
    end
  end

  describe 'GET #index' do
    it 'should return a list of serialized layout instances' do
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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
                                  .and change { Receptacle.count }.by(labware.receptacles.size)
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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.barcode).to include('TEST_')
    end

    it 'should create a labware with a given barcode' do
      labware = build(:labware_with_receptacles)

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
      create(:labware_with_receptacles, barcode: 'TEST_BARCODE')
      labware = build(:labware_with_receptacles)

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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
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
      labware = build(:labware_with_receptacles)

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
      labware = build(:labware_with_receptacles)

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
      labware = build(:labware_with_receptacles)

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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
                                  .and change { Receptacle.count }.by(labware.receptacles.size)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.external_id).to eq(labware.external_id)
      expect(new_labware.uuid.size).to eq(36)
      expect(new_labware.barcode).to include('TEST_XYZ_')

      new_labware.receptacles.zip(labware.receptacles) { |new_receptacle, receptacle_orig|
        expect(new_receptacle.material_uuid).to eq(receptacle_orig.material_uuid)
        expect(new_receptacle.location).to eq(receptacle_orig.location)
      }

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
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

      expect { post_json }.to change { Labware.count }.by(1)
                                  .and change { LabwareType.count }.by(0)
                                  .and change { Receptacle.count }.by(labware.receptacles.size)
      expect(response).to be_created
      labware_json = JSON.parse(response.body, symbolize_names: true)

      new_labware = Labware.last
      expect(new_labware.external_id).to eq(labware.external_id)
      expect(new_labware.uuid.size).to eq(36)
      expect(new_labware.barcode).to include('TEST_XYZ_')

      new_labware.receptacles.zip(labware.receptacles) { |new_receptacle, receptacle_orig|
        expect(new_receptacle.material_uuid).to eq(receptacle_orig.material_uuid)
        expect(new_receptacle.location).to eq(receptacle_orig.location)
      }

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
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

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq(@labware.external_id + '_changed')
      expect(new_labware.barcode).to eq(@labware.barcode + '_changed')

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
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
                  }
              }
          }
      }

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
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
      @labware = create(:labware_with_receptacles)
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
                                       .and change { Receptacle.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      expect(new_labware.external_id).to eq('')

      post_response = response
      get api_v1_labware_path(new_labware.uuid)
      get_response = response
      expect(post_response.body).to eq(get_response.body)
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

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
                                       .and change { Receptacle.count }.by(0)
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

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
                                       .and change { Receptacle.count }.by(0)
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

      expect { update_labware }.to change { Labware.count }.by(0)
                                       .and change { LabwareType.count }.by(0)
                                       .and change { Receptacle.count }.by(0)
      expect(response).to be_success

      new_labware = Labware.find(@labware.id)

      new_labware.receptacles.zip(@labware.receptacles).each { |new_receptacle, receptacle| 
        expect(new_receptacle.material_uuid).to eq(receptacle.material_uuid)
        expect(new_receptacle.location).to eq(receptacle.location)
      }
    end
  end
end