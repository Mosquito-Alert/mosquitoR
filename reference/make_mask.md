# Mask a number by rounding it down to the nearest mask value. Used by 'make_sampling_cells' for transforming exact locations into masked sampling cells. This is basically the same as the round_down function but it returns a character instead of a numeric.

Mask a number by rounding it down to the nearest mask value. Used by
'make_sampling_cells' for transforming exact locations into masked
sampling cells. This is basically the same as the round_down function
but it returns a character instead of a numeric.

## Usage

``` r
make_mask(x, mask = 0.05)
```

## Arguments

- x:

  The number to be masked

- mask:

  The masking value.

## Value

A character representing the result of the masking.

## Examples

``` r
make_mask(4.569, 0.05)
#> [1] "4.55"
```
