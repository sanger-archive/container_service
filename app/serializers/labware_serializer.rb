# See README.md for copyright details

class LabwareSerializer < ActiveModel::Serializer
  attributes  :id, :external_id, :barcode, :created_at

  belongs_to  :labware_type
  has_many    :receptacles
  has_many    :metadata

  def id
    object.uuid
  end
end
