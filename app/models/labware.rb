class Labware < ApplicationRecord
  belongs_to  :labware_type
  has_many    :receptacles, inverse_of: :labware

  accepts_nested_attributes_for :receptacles

  attr_accessor :barcode_prefix
  attr_accessor :barcode_info

  after_initialize :generate_uuid, if: 'uuid.nil?'
  after_save :generate_barcode, if: 'barcode.nil?'
  
  validates :uuid, uniqueness: {case_sensitive: false}, uuid: true
  validates :barcode, uniqueness: {case_sensitive: false}
  validates :barcode_prefix, presence: true, if: 'barcode.nil?'

  validate :one_location_per_receptacle, if: :labware_type

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end

  def generate_barcode
    info = barcode_info ? "#{barcode_info}_" : ''
    update_column(:barcode, "#{barcode_prefix}_#{info}#{id}")
  end

  def one_location_per_receptacle
    unless labware_type.layout.locations.size == receptacles.size
      errors.add :receptacles, I18n.t('errors.messages.receptacles.incorrect_count')
    end
  end
end
