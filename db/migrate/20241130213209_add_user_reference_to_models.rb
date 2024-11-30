class AddUserReferenceToModels < ActiveRecord::Migration[7.2]
  def change
    add_reference :models, :user, foreign_key: true
  end
end
