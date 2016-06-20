# See README.md for copyright details

class LayoutSerializer < ActiveModel::Serializer
  attributes :id, :name, :row, :column

  has_many :locations
end
