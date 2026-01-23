# Download device information from Senscape server using http get request.

Download device information from Senscape server using http get request.

## Usage

``` r
get_senscape_devices(api_key, page_size = 10)
```

## Arguments

- api_key:

  Senscape API key.

- page_size:

  The number items per page. Defaults to 10.

## Value

A tibble.

## Examples

``` r
if (nzchar(Sys.getenv("SENSCAPE_API_KEY"))) {
  my_devices = get_senscape_devices(api_key = Sys.getenv("SENSCAPE_API_KEY"))
  my_devices
}
```
