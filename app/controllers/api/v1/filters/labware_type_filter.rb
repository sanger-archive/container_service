# See README.md for copyright details

class Api::V1::Filters::LabwareTypeFilter
  def self.filter(params)
    labware_type = LabwareType.find_by(name: params[:type])
    labware_type ? { labware_type_id: labware_type.id } : nil
  end
end