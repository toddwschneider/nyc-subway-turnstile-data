class AddIndexToTurnstileObservations < ActiveRecord::Migration[6.0]
  def change
    add_index :turnstile_observations,
      %i(station line_names division),
      name: "index_turnstile_observations_on_subway_station"
  end
end
