# See README.md for copyright details

class CreateLabwareTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :labware_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
