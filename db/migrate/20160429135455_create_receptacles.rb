class CreateReceptacles < ActiveRecord::Migration[5.0]
  def change
    create_table :receptacles do |t|
      t.references :labware, foreign_key: true
      t.references :location, foreign_key: true

      t.timestamps
    end
  end
end
