class LabwareSerializer < ActiveModel::Serializer
  attributes :id, :external_id, :barcode

  belongs_to :labware_type

  def id
    object.uuid
  end
end
