# Download data from Senscape server using http get request.

Download data from Senscape server using http get request.

## Usage

``` r
get_senscape_data(
  api_key,
  page_size = 10,
  start_datetime,
  end_datetime,
  deviceIds = NA
)
```

## Arguments

- api_key:

  Path to Senscape API key.

- page_size:

  The number items per page. Defaults to 10.

- start_datetime:

  A datetime object that will be used as the lower bound to filter
  records.

- end_datetime:

  A datetime object that will be used as the upper bound to filter
  records.

- deviceIds:

  A character vector of all deviceIds from which data should be
  returned. If NA, then data will not be filtered by deviceId.

## Value

A tibble.

## Examples

``` r
if (nzchar(Sys.getenv("SENSCAPE_API_KEY"))) {
  new_smart_trap_data = get_senscape_data(api_key = Sys.getenv("SENSCAPE_API_KEY"),
  start_datetime = lubridate::as_datetime("2023-03-08"),
  end_datetime = lubridate::as_datetime("2023-03-09"),
   deviceIds = c("5f1076c998fda900151ff683", "5f1076c998fda900151ff683",
   "5f10762e98fda900151ff680", "5f10767c98fda900151ff681", "5f1076ae98fda900151ff682"))
  new_smart_trap_data
}
```
