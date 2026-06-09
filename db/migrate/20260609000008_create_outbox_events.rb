class CreateOutboxEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :outbox_events do |t|
      t.string :event_id, null: false
      t.string :event_type, null: false
      t.string :aggregate_type, null: false
      t.bigint :aggregate_id, null: false
      t.json :payload, null: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :outbox_events, :event_id, unique: true
    add_index :outbox_events, [ :aggregate_type, :aggregate_id ]
    add_index :outbox_events, :published_at
  end
end
