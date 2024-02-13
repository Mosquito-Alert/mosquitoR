
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mosquitoR

<!-- badges: start -->

[![Documentation](https://img.shields.io/static/v1?label=Documentation&message=html&color=informational)](https://mosquito-alert.github.io/mosquitoR/)
[![R-CMD-check](https://github.com/Mosquito-Alert/mosquitoR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Mosquito-Alert/mosquitoR/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/Mosquito-Alert/mosquitoR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/Mosquito-Alert/mosquitoR?branch=main)
<!-- badges: end -->

The goal of mosquitoR is provide to set of tools for analyzing data
associated with the Mosquito Alert citizen science system
(<http://mosquitoalert.com>), including Mosquito Alert citizen science
data, smart trap data from the Irideon Senscape API, and traditional
mosquito trap data.

IMPORTANT: This package is at an early stage of development, and we may
introduce “breaking” changes. In addition, please note that while the
package contains functions for working with the Irideon Senscape API, it
is not developed by Irideon and is not an official Irideon package.

## Installation

You can install the development version of mosquitoR from
[GitHub](https://github.com/) as follows:

``` r
# install.packages("devtools")
devtools::install_github("Mosquito-Alert/mosquitoR")
```

## Example

Turn a set of latitude and longitude coordinates into the standardized
sampling cell IDs use to organize Mosquito Alert’s anonymous background
tracks:

``` r
library(mosquitoR)
make_samplingcell_ids(lon=c(2.1686, 2.1032), lat=c(41.3874, 41.2098), mask=0.05)
#> [1] "2.15_41.35" "2.1_41.2"
```

Extract longitudes from a set of sampling cell IDs:

``` r
library(mosquitoR)
make_lonlat_from_samplingcell_ids(ids=c("2.15_41.35", "2.10_41.20"), type="lon")
#> [1] "2.15" "2.10"
```

Download smart trap data from the Senscape server using an API key:

``` r
library(mosquitoR)
library(lubridate)
#> 
#> Attaching package: 'lubridate'
#> The following objects are masked from 'package:base':
#> 
#>     date, intersect, setdiff, union
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(magrittr)
library(keyring)

SENSCAPE_API_KEY = key_get("SENSCAPE_API_KEY")

# get list of device IDs with names that start with ASPB
ASPB_deviceIds = get_senscape_devices(api_key = SENSCAPE_API_KEY) %>% filter(startsWith(name, "ASPB")) %>% pull(`_id`)
ASPB_deviceIds
#> [1] "5f1076e798fda900151ff684" "5f1076ae98fda900151ff682"
#> [3] "5f10762e98fda900151ff680" "5f10767c98fda900151ff681"
#> [5] "5f1076c998fda900151ff683"

# get all data from these devices within a specified interval
my_data = get_senscape_data(api_key = SENSCAPE_API_KEY, start_datetime = as_datetime("2023-03-08"), end_datetime = as_datetime("2023-03-09"), deviceIds = ASPB_deviceIds)
#> Getting Senscape Data from 2023-03-08 to 2023-03-09
#>   |                                                                              |                                                                      |   0%  |                                                                              |======================================================================| 100%
my_data
#> # A tibble: 241 × 11
#>    `_id`   temperature nice_name classification record_time humidity client_name
#>    <chr>         <dbl> <chr>     <chr>          <chr>          <dbl> <chr>      
#>  1 6408cd…        17.0 FILE_167… Culex female   2023-03-08…     61.1 ASPB 3 (Pe…
#>  2 6407d7…        12.3 FILE_167… Test pulse     2023-03-08…     56.4 ASPB 2 (Ho…
#>  3 6407d7…        12.8 FILE_167… Test pulse     2023-03-08…     61.3 ASPB 3 (Pe…
#>  4 6407d7…        12.7 FILE_167… Test pulse     2023-03-08…     60.4 ASPB 1 (Sa…
#>  5 6407d7…        14.0 FILE_167… Test pulse     2023-03-08…     61.1 ASPB 5 (Zo…
#>  6 6407d7…        14.7 FILE_167… Test pulse     2023-03-08…     72.5 ASPB 4 (Le…
#>  7 6407de…        12.6 FILE_167… Test pulse     2023-03-08…     60.3 ASPB 1 (Sa…
#>  8 6407de…        12.8 FILE_167… Test pulse     2023-03-08…     61.4 ASPB 3 (Pe…
#>  9 6407de…        12.2 FILE_167… Test pulse     2023-03-08…     56.5 ASPB 2 (Ho…
#> 10 6407de…        14.1 FILE_167… Test pulse     2023-03-08…     61.1 ASPB 5 (Zo…
#> # ℹ 231 more rows
#> # ℹ 4 more variables: client_type <chr>, processed <chr>, lat <lgl>, lng <lgl>
```

## Documentation

Online documentation can be found at
<https://mosquito-alert.github.io/mosquitoR/>.

## Contributing

If you want to contribute new functions, fix bugs, add documentation or
tests, etc., please do so on the `dev` branch. We are developing this
package using `devtools` and `testthat` and doing our best to follow the
guidelines and styles laid out in <https://r-pkgs.org>.

<!-- What is special about using `README.Rmd` instead of just `README.md`? You can include R chunks like so: -->
<!-- ```{r cars} -->
<!-- summary(cars) -->
<!-- ``` -->
<!-- You'll still need to render `README.Rmd` regularly, to keep `README.md` up-to-date. `devtools::build_readme()` is handy for this. You could also use GitHub Actions to re-render `README.Rmd` every time you push. An example workflow can be found here: <https://github.com/r-lib/actions/tree/v1/examples>. -->
<!-- You can also embed plots, for example: -->
<!-- ```{r pressure, echo = FALSE} -->
<!-- plot(pressure) -->
<!-- ``` -->
<!-- In that case, don't forget to commit and push the resulting figure files, so they display on GitHub and CRAN. -->
