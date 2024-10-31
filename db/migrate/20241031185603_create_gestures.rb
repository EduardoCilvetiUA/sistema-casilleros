class CreateGestures < ActiveRecord::Migration[7.2]
  def change
    create_table :gestures do |t|
      t.string :name
      t.string :symbol
      t.references :model, null: false, foreign_key: true

      t.timestamps
    end
  end
end
