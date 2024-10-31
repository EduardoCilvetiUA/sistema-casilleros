class CreateLockerEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :locker_events do |t|
      t.references :locker, null: false, foreign_key: true
      t.string :event_type
      t.boolean :success
      t.datetime :event_time

      t.timestamps
    end
  end
end
