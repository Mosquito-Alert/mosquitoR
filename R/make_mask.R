#' Mask a number by rounding it down to the nearest mask value. Used by 'make_sampling_cells' for transforming exact locations into masked sampling cells. This is basically the same as the round_down function but it returns a character instead of a numeric.
#'
#' @param x The number to be masked
#' @param mask The masking value.
#' @returns A character representing the result of the masking.
#' @export
#' @examples
#' make_mask(4.569, 0.05)
make_mask = function(x, mask = 0.05){
  as.character(round_down(x, mask))
}
