#' Inverse double-standardize a variable
#'
#' @param x A numeric vector to be inverse double standardized
#' @param d The vector used in the original double standardization.
#' @returns A numeric vector.
#' @export
invstd2 = function(x, d) {
  (x*2*sd(d, na.rm=T))+mean(d,na.rm=T)
}
