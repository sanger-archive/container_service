# See README.md for copyright details

class AddLayoutRefToLabwareTypes < ActiveRecord::Migration[5.0]
  def change
    add_reference :labware_types, :layout, foreign_key: true
  end
end
