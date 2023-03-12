#' Center and double-standardize a variable
#'
#' @param x A numeric vector to be centerd and double standardized.
#' @returns A numeric vector.
#' @export
std2 = function(x) {
  (x-mean(x,na.rm=T))/(2*sd(x, na.rm=T))
}
