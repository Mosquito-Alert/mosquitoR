#' Make complete time series aggregated by a given interval
#'
#' @param x A tibble containing exact datetimes for mosquito captures.
#' @param start A date or datetime object that will be used as the lower bound to filter records.
#' @param end A date or datetime object that will be used as the upper bound to filter records.
#' @param interval A string representing the interval over which data should be aggregated. Could be any string allowed by seq.Date.
#' @param groups A character vector representing the grouping variables to be included in the output.
#' @returns A tibble.
#' @import magrittr
#' @import dplyr
#' @export
make_aggregated_time_series = function(x, start=NA, end=NA, interval="day", groups = c("trap_ID", "TigacellID")){

  groups = c(groups, "classification")
  groups_and_date = c("date", "classification", groups)

  this_start = dplyr::if_else(is.na(start), min(x$date), start)
  this_end = dplyr::if_else(is.na(end), max(x$date), end)

  result = x %>% dplyr::group_by_at(groups_and_date) %>% dplyr::summarise(count = dplyr::n()) %>% dplyr::ungroup() %>% dplyr::group_by_at(groups) %>% tidyr::complete(date = seq.Date(this_start, this_end, by=interval), fill=list(count=0)) %>% ungroup() %>% filter(date >= this_start, date <= this_end) %>% tidyr::pivot_wider(names_from = classification, values_from = count)


  return(result)

}
