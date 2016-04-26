# See README.md for copyright details

class Layout < ApplicationRecord
  has_many :labware_types

  validates :name, presence: true
end
