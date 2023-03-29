
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mosquitoR

<!-- badges: start -->
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

# get list of device IDs with names that start with ASPB
ASPB_deviceIds = get_senscape_devices(key_path = "../auth/senscape_api_key.txt") %>% filter(startsWith(name, "ASPB")) %>% pull(`_id`)
ASPB_deviceIds
#> [1] "5f10762e98fda900151ff680" "5f1076e798fda900151ff684"
#> [3] "5f10767c98fda900151ff681" "5f1076c998fda900151ff683"
#> [5] "5f1076ae98fda900151ff682"

# get all data from these devices within a specified interval
my_data = get_senscape_data(key_path = "../auth/senscape_api_key.txt", start_datetime = as_datetime("2023-03-08"), end_datetime = as_datetime("2023-03-09"), deviceIds = ASPB_deviceIds)
#> Getting Senscape Data from 2023-03-08 to 2023-03-09
#>   |                                                                              |                                                                      |   0%  |                                                                              |======================================================================| 100%
my_data
#> # A tibble: 241 × 9
#>    `_id`             nice_…¹ class…² recor…³ clien…⁴ clien…⁵ proce…⁶   lat   lng
#>    <chr>             <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <dbl> <dbl>
#>  1 6408cd3a62588276… FILE_1… Culex … 2023-0… ASPB 3… Mosqui… 2023-0…  41.4  2.12
#>  2 6407d71a62588276… FILE_1… Test p… 2023-0… ASPB 2… Mosqui… 2023-0…  41.4  2.15
#>  3 6407d71c62588276… FILE_1… Test p… 2023-0… ASPB 3… Mosqui… 2023-0…  41.4  2.12
#>  4 6407d71bfcadc748… FILE_1… Test p… 2023-0… ASPB 1… Mosqui… 2023-0…  41.4  2.19
#>  5 6407d71d1969a50b… FILE_1… Test p… 2023-0… ASPB 5… Mosqui… 2023-0…  41.4  2.19
#>  6 6407d71c1969a50b… FILE_1… Test p… 2023-0… ASPB 4… Mosqui… 2023-0…  41.4  2.15
#>  7 6407de2362588276… FILE_1… Test p… 2023-0… ASPB 1… Mosqui… 2023-0…  41.4  2.19
#>  8 6407de22fcadc748… FILE_1… Test p… 2023-0… ASPB 3… Mosqui… 2023-0…  41.4  2.12
#>  9 6407de22a511e19f… FILE_1… Test p… 2023-0… ASPB 2… Mosqui… 2023-0…  41.4  2.15
#> 10 6407de2a1969a50b… FILE_1… Test p… 2023-0… ASPB 5… Mosqui… 2023-0…  41.4  2.19
#> # … with 231 more rows, and abbreviated variable names ¹​nice_name,
#> #   ²​classification, ³​record_time, ⁴​client_name, ⁵​client_type, ⁶​processed
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
