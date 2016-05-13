# See README.md for copyright details

class LabwareType < ApplicationRecord
  belongs_to  :layout

  validates   :name, presence: true, uniqueness: {case_sensitive: false}
end
