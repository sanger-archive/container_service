# See README.md for copyright details

class AddLayoutRefToLocations < ActiveRecord::Migration[5.0]
  def change
    add_reference :locations, :layout, foreign_key: true
  end
end
