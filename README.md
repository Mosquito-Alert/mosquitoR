
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mosquitoR

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/Mosquito-Alert/mosquitoR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/Mosquito-Alert/mosquitoR?branch=main)
<!-- badges: end -->

The goal of mosquitoR is provide to set of tools for analyzing data
associated with the Mosquito Alert citizen science system
(<http://mosquitoalert.com>), including Mosquito Alert citizen science
data, smart trap data from the Irideon Senscape API, and traditional
mosquito trap data.

This repository is currently private during the initial development
phase but will soon be made public.

## Installation

If you have a github Personal Access Token set up, tou can install the
development version of mosquitoR from [GitHub](https://github.com/)
with:

``` r
# install.packages("devtools")
devtools::install_github("Mosquito-Alert/mosquitoR")
```

Alternatively, if you are using an ssh key to access the private
repository, then you can install with:

``` r
# install.packages("devtools")
devtools::git@github.com:Mosquito-Alert/mosquitoR.git
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
