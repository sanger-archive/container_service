class Labware < ApplicationRecord
  belongs_to :labware_type

  validates :uuid, uniqueness: {case_sensitive: false}, uuid: true
  validates :barcode, uniqueness: {case_sensitive: false}

  after_initialize :generate_uuid, if: 'uuid.nil?'

  attr_accessor :barcode_prefix
  attr_accessor :barcode_info
  validates :barcode_prefix, presence: true, if: 'barcode.nil?'
  after_save :generate_barcode, if: 'barcode.nil?'

  private

  def generate_uuid
    self.uuid = UUID.new.generate
  end

  def generate_barcode
    info = barcode_info ? "#{barcode_info}_" : ''
    update_column(:barcode, "#{barcode_prefix}_#{info}#{id}")
  end
end
