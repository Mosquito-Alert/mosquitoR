#' Inverse double-standardize a variable
#'
#' @returns A numeric vector.
#' @export
invstd2 = function(x, d) {
  (x*2*sd(d, na.rm=T))+mean(d,na.rm=T)
}
