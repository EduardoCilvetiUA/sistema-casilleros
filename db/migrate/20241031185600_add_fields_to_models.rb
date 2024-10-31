class AddFieldsToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :file_path, :string
    add_column :models, :size_bytes, :integer
  end
end
