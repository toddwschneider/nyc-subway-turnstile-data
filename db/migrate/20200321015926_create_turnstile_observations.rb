class CreateTurnstileObservations < ActiveRecord::Migration[6.0]
  def change
    create_table :turnstile_observations do |t|
      t.text :control_area, null: false
      t.text :unit, null: false
      t.text :scp, null: false
      t.text :station, null: false
      t.text :line_names, null: false
      t.text :division, null: false
      t.timestamp :observed_at, null: false
      t.text :description, null: false
      t.bigint :entries, null: false
      t.bigint :exits, null: false
      t.bigint :net_entries
      t.bigint :net_exits
      t.text :filename, null: false
      t.timestamps
    end

    add_index :turnstile_observations,
      %i(control_area scp observed_at description),
      unique: true,
      name: "index_turnstile_observations_unique"

    add_index :turnstile_observations, :filename
    add_index :turnstile_observations, :division
  end
end
