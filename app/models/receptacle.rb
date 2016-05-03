class Receptacle < ApplicationRecord
  belongs_to  :labware, inverse_of: :receptacles
  belongs_to  :location

  validates :location, uniqueness: { scope: :labware }
  validate :location_of_correct_layout, if: [:labware, :location]
  validates :material_uuid, uuid: true, unless: "material_uuid.nil?" 

  private

  def location_of_correct_layout
    unless location.layout == labware.labware_type.layout
      errors.add :location, I18n.t('errors.messages.location_of_wrong_layout')
    end
  end
end
