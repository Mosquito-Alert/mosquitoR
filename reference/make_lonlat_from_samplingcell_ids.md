# Extract longitudes or latitudes from sampling cell IDs.

Extract longitudes or latitudes from sampling cell IDs.

## Usage

``` r
make_lonlat_from_samplingcell_ids(ids, type)
```

## Arguments

- ids:

  A character vector of sampling cell IDs

- type:

  A string indicating whether longitude ("lon") or latitude ("lat")
  should be extracted.

## Value

A numeric vector of longitude or latitude values.

## Examples

``` r
make_lonlat_from_samplingcell_ids(ids=c("2.15_41.35", "2.10_41.20"), type="lon")
#> [1] "2.15" "2.10"
```
