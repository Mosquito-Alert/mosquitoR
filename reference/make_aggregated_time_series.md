# Make complete time series aggregated by a given interval

Make complete time series aggregated by a given interval

## Usage

``` r
make_aggregated_time_series(
  x,
  start = NA,
  end = NA,
  interval = "day",
  groups = c("trap_ID", "TigacellID")
)
```

## Arguments

- x:

  A tibble containing exact datetimes for mosquito captures.

- start:

  A date or datetime object that will be used as the lower bound to
  filter records.

- end:

  A date or datetime object that will be used as the upper bound to
  filter records.

- interval:

  A string representing the interval over which data should be
  aggregated. Could be any string allowed by seq.Date.

- groups:

  A character vector representing the grouping variables to be included
  in the output.

## Value

A tibble.
