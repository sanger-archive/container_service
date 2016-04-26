# See README.md for copyright details

class CreateLayouts < ActiveRecord::Migration[5.0]
  def change
    create_table :layouts do |t|
      t.string :name

      t.timestamps
    end
  end
end
