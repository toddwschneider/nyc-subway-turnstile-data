class AddSubregionToStations < ActiveRecord::Migration[6.0]
  def change
    add_column :stations, :subregion, :text
    add_index :stations, :subregion
  end
end
