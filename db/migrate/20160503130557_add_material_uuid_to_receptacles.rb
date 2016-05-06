# See README.md for copyright details

class AddMaterialUuidToReceptacles < ActiveRecord::Migration[5.0]
  def change
    change_table :receptacles do |t|
      t.string :material_uuid, index: true
    end
  end
end
