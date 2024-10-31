class AddFieldsToControllers < ActiveRecord::Migration[7.2]
  def change
    add_column :controllers, :is_connected, :boolean, default: false
    add_column :controllers, :last_connection, :datetime
    add_reference :controllers, :model, null: false, foreign_key: true
  end
end
