# See README.md for copyright details

class Layout < ApplicationRecord
  has_many :labware_types
  has_many :locations

  validates :name, presence: true
  validates_presence_of :locations
end
