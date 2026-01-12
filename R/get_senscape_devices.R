#' Normalize Senscape device records into a tibble.
#'
#' @param devices A list of device records returned by the Senscape API.
#' @returns A tibble with one row per device.
#' @keywords internal
bind_senscape_devices = function(devices){
  if(is.null(devices) || !length(devices)){
    return(tibble::tibble())
  }

  repair_record_names = function(x){
    x = as.list(x)
    nms = names(x)
    if(is.null(nms)) nms = rep("", length(x))
    empty = is.na(nms) | !nzchar(nms)
    if(any(empty)){
      nms[empty] = paste0("...", seq_len(sum(empty)))
    }
    nms = make.unique(nms)
    names(x) = nms
    x
  }

  dplyr::bind_rows(lapply(devices, repair_record_names))
}

#' Download device information from Senscape server using http get request.
#'
#' @param api_key Senscape API key.
#' @param page_size The number items per page. Defaults to 10.
#' @param max_pages Maximum number of pages to fetch (safety limit).
#' @returns A tibble.
#' @export
#' @examples
#' my_devices = get_senscape_devices(api_key = Sys.getenv("SENSCAPE_API_KEY"))
#' my_devices
get_senscape_devices = function(api_key, page_size = 10, max_pages = 100){

  stopifnot(is.character(api_key), length(api_key) == 1, nzchar(api_key))
  stopifnot(is.numeric(page_size), length(page_size) == 1, page_size >= 1)
  stopifnot(is.numeric(max_pages), length(max_pages) == 1, max_pages >= 1)

  base_url = "https://senscape.eu/api/devices"
  all_devices = NULL

  # Senscape pagination is zero-based; iterate until API signals no further pages or the safety cap is reached.
  for(page_number in 0:(max_pages-1)){

    # Senscape API uses camelCase pagination parameters
    data_req <- httr::GET(base_url, httr::add_headers('authorization' = api_key),
                          query = list(pageNumber = page_number, pageSize = page_size))
    httr::stop_for_status(data_req)

    payload_text = httr::content(data_req, "text")
    # Preserve heterogeneous device fields for reliable row-binding
    payload = tryCatch(
      jsonlite::fromJSON(payload_text, simplifyVector = FALSE),
      error = function(e) stop("Failed to parse Senscape devices response: ", conditionMessage(e), call. = FALSE)
    )
    devices = payload$devices

    if(is.null(devices) || !length(devices)){
      break
    }

    devices_tbl = bind_senscape_devices(devices)
    all_devices = dplyr::bind_rows(all_devices, devices_tbl)

    if(!is.null(payload$count) && is.numeric(payload$count)){
      if(nrow(all_devices) >= payload$count) break
    }

    if(nrow(devices_tbl) < page_size) break
  }

  if(is.null(all_devices)){
    return(tibble::tibble())
  }

  if("_id" %in% names(all_devices)){
    all_devices = dplyr::distinct(all_devices, `_id`, .keep_all = TRUE)
  } else{
    warning("Devices payload did not include '_id'; returning records without deduplication", call. = FALSE)
  }

  return(all_devices)
}
