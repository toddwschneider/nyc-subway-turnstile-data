class CreateStations < ActiveRecord::Migration[6.0]
  def change
    create_table :stations do |t|
      t.text :name, null: false
      t.text :line_names, null: false
      t.text :division, null: false
      t.text :borough, null: false
      t.timestamps
    end

    add_index :stations, %i(name line_names division), unique: true
    add_index :stations, :borough
  end
end
