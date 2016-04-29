class CreateLabwares < ActiveRecord::Migration[5.0]
  def change
    create_table :labwares do |t|
      t.string :barcode, index: true
      t.string :external_id, index: true
      t.string :uuid, index: true
      t.belongs_to :labware_type

      t.timestamps
    end
  end
end
