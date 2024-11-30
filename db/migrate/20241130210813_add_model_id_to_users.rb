# db/migrate/[TIMESTAMP]_add_model_id_to_users.rb
class AddModelIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :active_model_id, :bigint
  end
end
