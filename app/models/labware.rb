# See README.md for copyright details

class Labware < ApplicationRecord
  belongs_to  :labware_type
  has_many    :receptacles, inverse_of: :labware
  has_many    :metadata, inverse_of: :labware

  accepts_nested_attributes_for :receptacles
  accepts_nested_attributes_for :metadata

  attr_accessor :barcode_prefix
  attr_accessor :barcode_info

  after_initialize  :generate_uuid, if: 'uuid.nil?'
  after_save        :generate_barcode, if: 'barcode.nil?'
  
  validates :uuid, uniqueness: {case_sensitive: false}, uuid: true
  validates :barcode, uniqueness: {case_sensitive: false}
  validates :barcode_prefix, presence: true, if: 'barcode.nil?'
  validate  :one_location_per_receptacle, if: :labware_type
  validate  :labware_type_immutable

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end

  def generate_barcode
    info = barcode_info ? "#{barcode_info}-" : ''
    update_column(:barcode, "#{barcode_prefix}-#{info}#{id.to_s.rjust(8, '0')}")
  end

  def one_location_per_receptacle
    unless labware_type.layout.locations.size == receptacles.size
      errors.add :receptacles, I18n.t('errors.messages.receptacles.incorrect_count')
    end
  end

  def labware_type_immutable
    if persisted? and "labware_type_id".in? changed
      errors.add :labware_type, I18n.t('errors.messages.immutable')
    end
  end
end
