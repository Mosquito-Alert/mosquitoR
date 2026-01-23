# Download Mosquito Alert report data from GitHub

Download Mosquito Alert report data from GitHub

## Usage

``` r
get_malert_data(source = "zenodo", doi = "10.5281/zenodo.597466")
```

## Arguments

- source:

  String. Source to download from. Options are github or zenodo.

- doi:

  String. Zenodo doi if downloading from Zenodo. Default is the doi that
  will always point to the most recent version: 10.5281/zenodo.597466.

## Value

A tibble.

## Examples

``` r
if (FALSE) { # \dontrun{
malert_reports = get_malert_data(source = "github")
malert_reports
} # }
```
