class CreateLockers < ActiveRecord::Migration[7.2]
  def change
    create_table :lockers do |t|
      t.integer :number
      t.boolean :state
      t.string :owner_email
      t.references :controller, null: false, foreign_key: true

      t.timestamps
    end
  end
end
