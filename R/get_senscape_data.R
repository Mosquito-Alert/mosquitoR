#' Download data from Senscape server using http get request.
#'
#' @param key_path Path to Senscape API key.
#' @param page_size The number items per page. Defaults to 10.
#' @param start_datetime A datetime object that will be used as the lower bound to filter records.
#' @param end_datetime A datetime object that will be used as the upper bound to filter records.
#' @param deviceIds A character vector of all deviceIds from which data should be returned.
#' @returns A tibble.
#' @export
#' @examples
#' new_smart_trap_data = get_senscape_data(key_path = "../auth/senscape_api_key.txt", start_datetime = lubridate::as_datetime("2023-03-08"), end_datetime = lubridate::as_datetime("2023-03-09"), deviceIds = c("5f1076c998fda900151ff683", "5f1076c998fda900151ff683", "5f10762e98fda900151ff680", "5f10767c98fda900151ff681", "5f1076ae98fda900151ff682"))
#' new_smart_trap_data
get_senscape_data = function(key_path, page_size = 10, start_datetime, end_datetime, deviceIds){

  httr::set_config(httr::config(ssl_verifypeer = 0L))

  deviceId_query = paste0("deviceId=", deviceIds, "&", collapse = '')


  this_start_datetime = start_datetime

  final_result = NULL

  chunksize_days = 30

  n_iterations = as.integer(ceiling(difftime(end_datetime, start_datetime, units = "days")/chunksize_days))

  this_end_datetime = this_start_datetime

  message(paste0("Getting Senscape Data from ", start_datetime, " to ", end_datetime))

  i = 0
  pb <- txtProgressBar(min = 0, max = n_iterations, initial = 0, style = 3)

  while(this_end_datetime < end_datetime){

    this_end_datetime = min(this_start_datetime + lubridate::days(chunksize_days), end_datetime)

    #  print(this_end_datetime)
    #  flush.console()

    start = lubridate::stamp("2021-09-22T00:00:00.000Z", orders = "%Y-%Om-%dT%H:%M:%OS3Z", exact = TRUE, quiet = TRUE)(lubridate::with_tz(this_start_datetime, "UTC"))

    end = lubridate::stamp("2021-09-22T00:00:00.000Z", orders = "%Y-%Om-%dT%H:%M:%OS3Z", exact = TRUE, quiet = TRUE)(lubridate::with_tz(this_end_datetime, "UTC"))

    this_query = paste0("https://senscape.eu/api/data?", deviceId_query, "sortOrder=asc&sortField=record_time&filterStart=", start, "&filterEnd=", end)

    data_req <- httr::GET(this_query, httr::add_headers('authorization' = readr::read_lines(key_path)))

    sense_data_count = tibble::as_tibble(jsonlite::fromJSON(httr::content(data_req, "text"))$count)

    total_pages = (as.integer(sense_data_count/page_size)+1)

    this_smart_trap_data = dplyr::bind_rows(lapply(0:total_pages, function(i){
      # print(paste0("targets page ", i, " of ", total_pages))
      #  flush.console()
      data_req <- httr::GET(paste0(this_query, "&pageNumber=", i, "&pageSize=", page_size), httr::add_headers('authorization' = readr::read_lines(key_path)))
      tibble::as_tibble(jsonlite::fromJSON(httr::content(data_req, "text"))$samples)
    }))


    this_query_pulses = paste0("https://senscape.eu/api/data?", deviceId_query, "classification=Test%20pulse&sortOrder=asc&sortField=record_time&filterStart=", start, "&filterEnd=", end)

    data_req <- httr::GET(this_query_pulses, httr::add_headers('authorization' = readr::read_lines(key_path)))

    sense_data_count = tibble::as_tibble(jsonlite::fromJSON(httr::content(data_req, "text"))$count)

    total_pages = (as.integer(sense_data_count/page_size)+1)

    this_smart_trap_data_pulses = dplyr::bind_rows(lapply(0:total_pages, function(i){
      #    print(paste0("pulses page ", i, " of ", total_pages))
      #    flush.console()
      data_req <- httr::GET(paste0(this_query_pulses, "&pageNumber=", i, "&pageSize=", page_size), httr::add_headers('authorization' = readr::read_lines(key_path)))
      tibble::as_tibble(jsonlite::fromJSON(httr::content(data_req, "text"))$samples)
    }))

    final_result = dplyr::bind_rows(final_result, this_smart_trap_data, this_smart_trap_data_pulses)

    this_start_datetime = this_end_datetime

    message(paste0("Working on: ", lubridate::as_date(this_start_datetime)))
    flush.console()
    i = i + 1
    setTxtProgressBar(pb, value = i)

  }
  close(pb)

  # taking only distinct rows now because there are a small number of records that end up being duplicated. This appears to happen because, despite what the API documentation says, filterStart seems to give records greater than or equal to the date, not just greater than it. So there are a small number of records that fall exactly at the of the filter range in one iteration through the loop and then get picked up at the beginning of the range in the next iteration.
  final_result = dplyr::distinct(final_result)

  return(final_result)

}
