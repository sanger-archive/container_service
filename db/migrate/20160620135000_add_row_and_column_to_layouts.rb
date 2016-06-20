# See README.md for copyright details

class AddRowAndColumnToLayouts < ActiveRecord::Migration[5.0]
  def change
    change_table :layouts do |t|
      t.integer :row
      t.integer :column
    end
  end
end
