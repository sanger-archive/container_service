# See README.md for copyright details

class Metadatum < ApplicationRecord
  belongs_to :labware

  validates :key, presence: true
end
