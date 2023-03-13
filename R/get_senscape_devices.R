#' Download device information from Senscape server using http get request.
#'
#' @param key_path Path to Senscape API key.
#' @returns A tibble.
#' @export
#' @examples
#' my_devices = get_senscape_devices(key_path = "../auth/senscape_api_key.txt")
#' my_devices
get_senscape_devices = function(key_path){
  device_check = httr::GET("https://senscape.eu/api/devices", httr::add_headers('authorization' = readr::read_lines(key_path)))
  return(tibble::as_tibble(jsonlite::fromJSON(httr::content(device_check, "text"))$devices))
}
