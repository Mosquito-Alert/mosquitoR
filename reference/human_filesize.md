# Human-readable binary file size

Takes an integer (referring to number of bytes) and returns an optimally
human-readable
[binary-prefixed](https://en.wikipedia.org/wiki/Binary_prefix) byte size
(KiB, MiB, GiB, TiB, PiB, EiB). The function is vectorised.

## Usage

``` r
human_filesize(x)
```

## Arguments

- x:

  A positive integer, i.e. the number of bytes (B). Can be a vector of
  file sizes.

## Value

A character vector.

## Author

Floris Vanderhaeghe, <floris.vanderhaeghe@inbo.be>
