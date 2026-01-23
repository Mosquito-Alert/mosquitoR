# Creates standard sampling cell IDs by masking a set of longitude and latitude values.

Creates standard sampling cell IDs by masking a set of longitude and
latitude values.

## Usage

``` r
make_samplingcell_ids(lon, lat, mask = 0.05)
```

## Arguments

- lon:

  A vector of longitudes to be masked

- lat:

  A vector of latitudes to be masked

- mask:

  The masking value.

## Value

A character vector of sampling cell IDs.

## Examples

``` r
make_samplingcell_ids(lon=c(2.1686, 2.1032), lat=c(41.3874, 41.2098), 0.05)
#> [1] "2.15_41.35" "2.1_41.2"  
```
