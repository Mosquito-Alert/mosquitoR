#' Download Mosquito Alert report data from GitHub
#'
#' @param source String. Source to download from. Options are github or zenodo.
#' @param doi String. Zenodo doi if downloading from Zenodo. Default is the doi that will always point to the most recent version: 10.5281/zenodo.597466.
#' @returns A tibble.
#' @export
#' @examples
#' malert_reports = get_malert_data(source = "github")
#' malert_reports
get_malert_data = function(source = "zenodo", doi = "10.5281/zenodo.597466") {
  this_temp_file <- tempfile()
  if (source == "github") {
    temp = this_temp_file
    download.file(
      "https://github.com/MosquitoAlert/Data/raw/master/all_reports.zip",
      destfile = temp
    )
  } else if (source == "zenodo" & !is.na(doi)) {
    dir.create(this_temp_file, showWarnings = FALSE)
    download_zenodo(doi = doi, path = this_temp_file)
    this_file = list.files(this_temp_file)
    this_temp_file_zip = file.path(this_temp_file, list.files(this_temp_file))
    outer_file_name = unzip(
      this_temp_file_zip,
      exdir = this_temp_file,
      list = TRUE
    )[1, 1]
    unzip(this_temp_file_zip, exdir = this_temp_file)
    temp = file.path(this_temp_file, outer_file_name, "all_reports.zip")
  } else {
    stop(
      "Error: This function currently only supports downloads from Github or Zenodo"
    )
  }
  # Create temporary directory for extracted JSON files

  temp_extract_dir <- tempfile(pattern = "malert_json_")
  dir.create(temp_extract_dir)
  on.exit(unlink(temp_extract_dir, recursive = TRUE), add = TRUE)
 
  # Extract entire zip archive once (more efficient than unz() for each file)
  tryCatch({
    unzip(temp, exdir = temp_extract_dir)
  }, error = function(e) {
    stop("Failed to extract zip archive: ", e$message)
  })
 
  reports = bind_rows(lapply(
    2014:lubridate::year(lubridate::today()),
    function(this_year) {
      print(this_year)
      flush.console()
      
      this_file = file.path(
        temp_extract_dir,
        "home/webuser/webapps/tigaserver/static",
        paste0("all_reports", this_year, ".json")
      )
      
      # Skip if file doesn't exist (e.g., future years)
      if (!file.exists(this_file)) {
        return(NULL)
      }
      
      # Parse with RcppSimdJson (much faster than jsonlite::fromJSON)
      parsed_data <- tryCatch({
        RcppSimdJson::fload(this_file, max_simplify_lvl = "data_frame")
      }, error = function(e) {
        warning("RcppSimdJson failed for year ", this_year, ": ", e$message,
                ". Falling back to jsonlite.")
        return(jsonlite::fromJSON(this_file, flatten = TRUE))
      })
      
      # Convert nested list-columns to data frames for flattening
      # These columns need to be data frames for jsonlite::flatten() to work
      # Include tiger_responses and site_responses which contain q1/q2/q3_response data in older years
      struct_cols <- c("movelab_annotation", "movelab_annotation_euro",
                       "tiger_responses_text", "site_responses_text",
                       "tiger_responses", "site_responses")
      
      for (col in struct_cols) {
        if (!col %in% names(parsed_data)) next
        val <- parsed_data[[col]]
        if (!is.list(val) || is.data.frame(val)) next
        
        n_rows <- nrow(parsed_data)
        
        # Find first non-null/non-empty element to get schema
        is_empty <- vapply(val, function(x) is.null(x) || length(x) == 0, logical(1))
        first_valid_idx <- which(!is_empty)[1]
        
        if (is.na(first_valid_idx)) {
          # All NULL/empty - replace with NA (flatten will ignore)
          parsed_data[[col]] <- NA
          next
        }
        
        first_valid <- val[[first_valid_idx]]
        if (is.data.frame(first_valid)) next
        
        # Get schema from first valid element
        schema <- names(first_valid)
        na_row <- setNames(as.list(rep(NA, length(schema))), schema)
        
        # Fast handling of empty/NULL elements (truly empty lists)
        is_empty <- lengths(val) == 0
        if (any(is_empty)) {
           val[is_empty] <- list(na_row)
        }
        
        # Handle case where element exists but all its fields are NULL/length-0 (which rbindlist treats as 0 rows)
        # This is faster than converting everything to data.frames
        is_all_nulls <- vapply(val, function(x) length(x) > 0 && all(lengths(x) == 0), logical(1))
        if (any(is_all_nulls)) {
           val[is_all_nulls] <- list(na_row)
        }
        
        # Use rbindlist for fast binding
        # We must use fill=TRUE because some rows might be missing new columns
        result <- data.table::rbindlist(val, fill = TRUE, use.names = TRUE)
        
        parsed_data[[col]] <- as.data.frame(result, check.names=FALSE)
      }
      
      # Apply jsonlite::flatten() to expand nested data frame columns
      flattened_data <- jsonlite::flatten(parsed_data)
      
      # Cleanup: Remove parent struct columns that shouldn't appear in final output
      # - tiger_responses: always remove (original jsonlite doesn't produce this column)
      # - tiger_responses_text, site_responses_text: remove if still data.frame
      if ("tiger_responses" %in% names(flattened_data)) {
        flattened_data$tiger_responses <- NULL
      }
      
      for (col in c("tiger_responses_text", "site_responses_text")) {
        if (col %in% names(flattened_data) && is.data.frame(flattened_data[[col]])) {
          flattened_data[[col]] <- NULL
        }
      }
      
      # site_responses becomes logical NA column per original jsonlite behavior
      # when it's an empty data.frame with 0 columns
      if ("site_responses" %in% names(flattened_data) && 
          is.data.frame(flattened_data$site_responses) &&
          ncol(flattened_data$site_responses) == 0) {
        flattened_data$site_responses <- NA
      }
      
      as_tibble(flattened_data)
    }
  ))
  unlink(this_temp_file)
  return(reports)
}
