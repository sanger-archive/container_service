# See README.md for copyright details

class Location < ApplicationRecord
  belongs_to :layout

  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :layout }
end
