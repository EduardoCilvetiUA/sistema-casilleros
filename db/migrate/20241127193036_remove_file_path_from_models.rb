class RemoveFilePathFromModels < ActiveRecord::Migration[7.2]
  def change
    remove_column :models, :file_path, :string
  end
end
