# See README.md for copyright details

class AddUniqueKeyConstraintsToMetadata < ActiveRecord::Migration[5.0]
  def change
    add_index :metadata, [:key, :labware_id], :unique => true
  end
end
