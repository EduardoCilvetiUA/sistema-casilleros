class AddFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_superuser, :boolean, default: false
  end
end
