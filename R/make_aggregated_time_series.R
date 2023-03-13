#' Make complete time series aggregated by a given interval. TODO: WE NEED TO MAKE THIS MORE GENERAL STILL
#'
#' @param x A tibble containing exact datetimes for mosquito captures.
#' @param classification A character vector of the classifications to be used. (The tibble will be filtered for these and the final counts will be for all captures with any of these classifications).
#' @param start A date or datetime object that will be used as the lower bound to filter records.
#' @param end A date or datetime object that will be used as the upper bound to filter records.
#' @param interval A string representing the interval over which data should be aggregated. Could be any string allowed by seq.Date.
#' @returns A tibble.
#' @import magrittr
#' @import dplyr
#' @export
make_aggregated_time_series = function(x, classification, start=NA, end=NA, interval="day"){

  this_start = dplyr::if_else(is.na(start), min(x$date), start)
  this_end = dplyr::if_else(is.na(end), max(x$date), end)

  result = x %>% dplyr::filter(classification %in% classification) %>% dplyr::select(date, trap_ID, TigacellID) %>% dplyr::group_by(date, trap_ID, TigacellID) %>% dplyr::summarise(count = dplyr::n()) %>% dplyr::ungroup() %>% dplyr::group_by(trap_ID, TigacellID) %>% complete(date = seq.Date(this_start, this_end, by=interval), fill=list(count=0)) %>% ungroup() %>% filter(date >= this_start, date <= this_end)

  return(result)

}
