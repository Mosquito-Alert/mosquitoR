#' Return the number of decimal places in a given value
#'
#' @param x The value for which the number of decimal places will be returned.
#' @returns An integer representing the number of decimal places in x.
#' @export
#' @examples
#' decimal_places(4.56)
decimal_places <- function(x) {
  if ((x %% 1) != 0) {
    nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed=TRUE)[[1]][[2]])
  } else {
    return(0)
  }
}
