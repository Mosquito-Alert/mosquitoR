#' Round a given number x downward to the nearest n.
#'
#' @param x The number to be rounded.
#' @param n The number to be rounded.
#' @returns The numeric result of the downward rounding.
#' @export
#' @examples
#' round_down(4.569, 0.05)
round_down = function(x, n) round( floor( (x*1000)/ (n*1000))*n, decimal_places(n))
