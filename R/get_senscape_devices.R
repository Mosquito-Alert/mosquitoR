#' Download device information from Senscape server using http get request.
#'
#' @param api_key Senscape API key.
#' @returns A tibble.
#' @export
#' @examples
#' my_devices = get_senscape_devices(api_key = SENSCAPE_API_KEY)
#' my_devices
get_senscape_devices = function(api_key){
  device_check = httr::GET("https://senscape.eu/api/devices", httr::add_headers('authorization' = api_key))
  return(tibble::as_tibble(jsonlite::fromJSON(httr::content(device_check, "text"))$devices))
}
