#' Extract longitudes or latitudes from sampling cell IDs.
#'
#' @param ids A character vector of sampling cell IDs
#' @param type A string indicating whether longitude ("lon") or latitude ("lat") should be extracted.
#' @returns A numeric vector of longitude or latitude values.
#' @export
#' @examples
#' make_lonlat_from_samplingcell_ids(ids=c("2.15_41.35", "2.10_41.20"), type="lon")
make_lonlat_from_samplingcell_ids = function(ids, type){
  if(type == "lon") t = 1
  else if(type == "lat") t = 2
  return(unlist(lapply(ids, function(id) str_split(id, "_")[[1]][t])))
}
