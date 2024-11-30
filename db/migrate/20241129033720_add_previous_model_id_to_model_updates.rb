class AddPreviousModelIdToModelUpdates < ActiveRecord::Migration[7.0]
  def change
    add_column :model_updates, :previous_model_id, :bigint
    add_foreign_key :model_updates, :models, column: :previous_model_id
    add_index :model_updates, :previous_model_id
  end
end
