#' Simple predicate function for sf to filter all objects that are not covered by another one
#'
#' @param x Object to be filtered.
#' @param y Object used for filtering.
#' @returns Boolean.
#' @export
not_covered_by = function(x, y) !sf::st_covered_by(x, y)
