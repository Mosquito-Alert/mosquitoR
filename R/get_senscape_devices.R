#' Download device information from Senscape server using http get request.
#'
#' @param api_key Senscape API key.
#' @returns A tibble.
#' @export
#' @examples
#' my_devices = get_senscape_devices(api_key = Sys.getenv("SENSCAPE_API_KEY"))
#' my_devices
get_senscape_devices = function(api_key, page_size = 10){

  data_req = httr::GET("https://senscape.eu/api/devices", httr::add_headers('authorization' = api_key))

  sense_data_count = tibble::as_tibble(jsonlite::fromJSON(httr::content(data_req, "text"))$count)

  total_pages = (as.integer(sense_data_count/page_size)+1)

  device_check = dplyr::bind_rows(lapply(0:total_pages, function(i){

    data_req <- httr::GET("https://senscape.eu/api/devices", httr::add_headers('authorization' = api_key))

    tibble::as_tibble(jsonlite::fromJSON(httr::content(data_req, "text"))$devices)

  }))

  return(device_check)
}
