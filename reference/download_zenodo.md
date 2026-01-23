# Get data from a Zenodo archive

This function will download an entire archive from Zenodo
(<https://zenodo.org>). Taken from the n2khab R package
(<https://github.com/inbo/n2khab>). It only works for Zenodo created DOI
(not when the DOI is for example derived from Zookeys.)

## Usage

``` r
download_zenodo(doi, path = ".", parallel = TRUE, quiet = FALSE)
```

## Arguments

- doi:

  a doi pointer to the Zenodo archive starting with '10.5281/zenodo.'.
  See examples.

- path:

  Path where the data must be downloaded. Defaults to the working
  directory.

- parallel:

  Logical. If `TRUE` (the default), files will be downloaded
  concurrently for multi-file records. Of course, the operation is
  limited by bandwidth and traffic limitations.

- quiet:

  Logical (`FALSE` by default). Do you want to suppress informative
  messages (not warnings)?

## Author

Hans Van Calster, <hans.vancalster@inbo.be>

Floris Vanderhaeghe, <floris.vanderhaeghe@inbo.be>

## Examples

``` r
if (FALSE) { # \dontrun{
# Example download of an archive containing a single zip
download_zenodo(doi = "10.5281/zenodo.1283345")
download_zenodo(doi = "10.5281/zenodo.1283345", quiet = TRUE)
# Example download of an archive containing multiple files
# using parallel download
# (multiple files will be simultaneously downloaded)
download_zenodo(doi = "10.5281/zenodo.1172801", parallel = TRUE)
# Example download of an archive containing a single pdf file
download_zenodo(doi = "10.5281/zenodo.168478")
} # }
```
