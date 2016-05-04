class ReceptacleSerializer < ActiveModel::Serializer
  attributes :id, :material_uuid
  has_one :location
end
