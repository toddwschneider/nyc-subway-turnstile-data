# NYC Subway Turnstile Data

Download NYC subway turnstile data files from [the MTA's website](http://web.mta.info/developers/turnstile.html) and load them into a database

Hastily put together in March 2020, structured as a Rails app but the only functionality is to download files and load them into a Postgres table called `turnstile_observations`

The repo does not currently support the MTA file formats for the time period 5/5/2010–10/11/2014

## Dashboard

[See here for a dashboard with up-to-date graphs](https://toddwschneider.com/dashboards/nyc-subway-turnstiles/). Data updates weekly on Saturday mornings.

## Initialize database

`bundle exec rake db:setup`

## Example usage

From the Rails console, import a single file:

```rb
TurnstileObservation.import_turnstile_observations(date: "2020-03-21".to_date)
```

Import all files:

```rb
TurnstileObservation.
  all_available_dates.
  select { |d| d >= TurnstileObservation::FIRST_DATE_WITH_NEW_FORMAT }.
  each { |d| TurnstileObservation.import_turnstile_observations(date: d) }
```

After importing files, you have to run another query to set the `net_entries` and `net_exits` colums:

```rb
TurnstileObservation.set_net_entries_and_net_exits
```
