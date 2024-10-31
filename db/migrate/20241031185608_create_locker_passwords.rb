class CreateLockerPasswords < ActiveRecord::Migration[7.2]
  def change
    create_table :locker_passwords do |t|
      t.references :locker, null: false, foreign_key: true
      t.references :gesture, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
