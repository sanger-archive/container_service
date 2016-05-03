class ReceptacleSerializer < ActiveModel::Serializer
  attributes :id
  has_one :labware
  has_one :location
end
