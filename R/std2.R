#' Double-standardize a variable
#'
#' @returns A numeric vector.
#' @export
std2 = function(x) {
  (x-mean(x,na.rm=T))/(2*sd(x, na.rm=T))
}
