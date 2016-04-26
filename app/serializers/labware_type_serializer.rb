# See README.md for copyright details

class LabwareTypeSerializer < ActiveModel::Serializer
  attributes :id, :name

  belongs_to :layout
end
