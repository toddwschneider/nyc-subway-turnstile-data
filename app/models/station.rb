class Station < ApplicationRecord
  BOROUGH_NAMES = [
    "Brooklyn",
    "Bronx",
    "Manhattan",
    "New Jersey",
    "Queens",
    "Staten Island"
  ]

  validates :name, :line_names, :division, :borough, presence: true
  validates :borough, inclusion: {in: BOROUGH_NAMES}

  def self.import_stations_from_csv
    CSV.foreach(Rails.root.join("lib/stations.csv"), headers: true, header_converters: :symbol) do |row|
      station = find_or_initialize_by(
        name: row.fetch(:station),
        line_names: row.fetch(:line_names),
        division: row.fetch(:division)
      )

      station.borough = row.fetch(:borough)
      station.subregion = row.fetch(:subregion)

      station.save!
    end
  end
end
