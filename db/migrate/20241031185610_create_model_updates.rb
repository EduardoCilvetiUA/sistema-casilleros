class CreateModelUpdates < ActiveRecord::Migration[7.2]
  def change
    create_table :model_updates do |t|
      t.references :controller, null: false, foreign_key: true
      t.references :model, null: false, foreign_key: true
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end

