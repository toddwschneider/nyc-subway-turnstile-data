class TurnstileObservation < ApplicationRecord
  BASE_URL = "http://web.mta.info/developers/data/nyct/turnstile"
  FIRST_DATE_WITH_NEW_FORMAT = Date.new(2014, 10, 18)
  HOME_URL = "http://web.mta.info/developers/turnstile.html"
  SUBWAY_DIVISIONS = %w(BMT IND IRT)

  scope :subway, -> { where(division: SUBWAY_DIVISIONS) }

  def self.import_turnstile_observations(date:)
    if date < FIRST_DATE_WITH_NEW_FORMAT
      raise "date can't be before #{FIRST_DATE_WITH_NEW_FORMAT}"
    end

    filename = "turnstile_#{date.strftime("%y%m%d")}.txt"
    local_file_path = Rails.root.join("tmp", "turnstile_files", filename).to_s
    url = "#{BASE_URL}/#{filename}"

    download_turnstile_file(url: url, path: local_file_path)

    rows = CSV.open(local_file_path, headers: true, header_converters: :symbol)

    copy_schema = %w(control_area unit scp station line_names division observed_at description entries exits filename created_at updated_at)
    copy_sql = "COPY turnstile_observations (#{copy_schema.join(", ")}) FROM stdin;"
    now = Time.zone.now

    transaction do
      where(filename: filename).delete_all

      pg_connection.copy_data(copy_sql, copy_encoder) do
        rows.each do |row|
          date_string = "#{row.fetch(:date)} #{row.fetch(:time)}"
          observed_at = Time.zone.strptime(date_string, "%m/%d/%Y %H:%M:%S")

          entries = parse_integer(row.fetch(:entries))
          exits = parse_integer(row.fetch(:exits))
          next unless entries && exits

          row_for_copy = [
            row.fetch(:ca),
            row.fetch(:unit),
            row.fetch(:scp),
            row.fetch(:station),
            row.fetch(:linename),
            row.fetch(:division),
            observed_at,
            row.fetch(:desc),
            entries,
            exits,
            filename,
            now,
            now
          ]

          pg_connection.put_copy_data(row_for_copy)
        end
      end
    end
  end

  def self.set_net_entries_and_net_exits
    query = <<-SQL
      WITH net_observations AS (
        SELECT
          id,
          entries - lag(entries, 1) OVER w AS calculated_net_entries,
          exits - lag(exits, 1) OVER w AS calculated_net_exits
        FROM turnstile_observations
        WINDOW w AS (PARTITION BY control_area, unit, scp ORDER BY observed_at)
      )
      UPDATE turnstile_observations
      SET
        net_entries = CASE WHEN abs(calculated_net_entries) < 10000 THEN abs(calculated_net_entries) END,
        net_exits = CASE WHEN abs(calculated_net_exits) < 10000 THEN abs(calculated_net_exits) END
      FROM net_observations
      WHERE turnstile_observations.id = net_observations.id
    SQL

    connection.execute(query)
  end

  def self.all_available_dates
    doc = Nokogiri::HTML(HTTParty.get(HOME_URL).body)
    url_regex = /data\/nyct\/turnstile\/turnstile_(\d{6}).txt$/i

    doc.css("a").map do |a|
      next unless yymmdd = a["href"] && a["href"][url_regex, 1]
      Date.strptime(yymmdd, "%y%m%d")
    end.compact
  end

  def self.download_turnstile_file(url:, path:, force: false)
    return if File.exists?(path) && !force
    FileUtils.mkdir_p(File.dirname(path))
    Down.download(url, destination: path)
  end

  def self.weekly_subway_entries
    subway.
      where.not(net_entries: nil).
      select("
        date_trunc('week', observed_at + '2 days'::interval)::date - '2 days'::interval AS week,
        sum(net_entries) AS entries
      ").
      group(:week).
      order(:week).
      map { |o| [o.week, o.entries&.to_i] }
  end

  def self.weekly_subway_entries_by_borough
    query = <<-SQL
      SELECT
        coalesce(s.borough, 'Unknown') AS borough,
        date_trunc('week', o.observed_at + '2 days'::interval)::date - '2 days'::interval AS week,
        sum(o.net_entries) AS entries
      FROM turnstile_observations o
        LEFT JOIN stations s
          ON o.station = s.name
          AND o.line_names = s.line_names
          AND o.division = s.division
      WHERE o.division IN (:subway_divisions)
      GROUP BY 1, 2
      ORDER BY 1, 2
    SQL

    find_by_sql([query, subway_divisions: SUBWAY_DIVISIONS]).
      map { |o| [o.week.to_date, o.borough, o.entries&.to_i] }
  end

  private

  def self.pg_connection
    connection.raw_connection
  end

  def self.copy_encoder
    PG::TextEncoder::CopyRow.new
  end

  def self.parse_integer(value_string)
    return unless value_string.present?
    Integer(value_string.strip, 10)
  end
end
