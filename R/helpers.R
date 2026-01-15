#' Download Mosquito Alert zip archive (internal helper)
#'
#' @param source String. Source to download from. Options are "github" or "zenodo".
#' @param doi String. Zenodo doi if downloading from Zenodo.
#' @param destfile String. Path where the zip file should be saved.
#' @returns String. Path to the downloaded zip file.
#' @keywords internal
download_malert_zip <- function(source, doi, destfile) {
  if (source == "github") {
    download.file(
      "https://github.com/MosquitoAlert/Data/raw/master/all_reports.zip",
      destfile = destfile
    )
    return(destfile)
    
  } else if (source == "zenodo" && !is.na(doi)) {
    # Zenodo download involves extracting a zip from Zenodo to find all_reports.zip
    zenodo_temp_dir <- tempfile(pattern = "zenodo_dl_")
    dir.create(zenodo_temp_dir, showWarnings = FALSE)
    on.exit(unlink(zenodo_temp_dir, recursive = TRUE), add = TRUE)
    
    download_zenodo(doi = doi, path = zenodo_temp_dir)
    
    # Zenodo archives usually contain a single folder with the contents
    zip_candidates <- list.files(zenodo_temp_dir, pattern = "\\.zip$", recursive = TRUE, full.names = TRUE)
    
    # If there's a zip file inside the zenodo download, it might be the one we want.
    # In the original implementation, it was unzipped and then looked for all_reports.zip
    
    # Original logic:
    # this_file = list.files(this_temp_file)
    # this_temp_file_zip = file.path(this_temp_file, list.files(this_temp_file))
    # outer_file_name = unzip(this_temp_file_zip, exdir = this_temp_file, list = TRUE)[1, 1]
    # unzip(this_temp_file_zip, exdir = this_temp_file)
    # temp = file.path(this_temp_file, outer_file_name, "all_reports.zip")
    
    # Let's adapt it:
    zenodo_zip <- list.files(zenodo_temp_dir, full.names = TRUE)[1] # Assuming first file is the record zip
    
    outer_file_name <- unzip(zenodo_zip, exdir = zenodo_temp_dir, list = TRUE)[1, 1]
    unzip(zenodo_zip, exdir = zenodo_temp_dir)
    
    reports_zip <- file.path(zenodo_temp_dir, outer_file_name, "all_reports.zip")
    
    if (!file.exists(reports_zip)) {
      stop("Could not find 'all_reports.zip' in the Zenodo archive.")
    }
    
    file.copy(reports_zip, destfile, overwrite = TRUE)
    return(destfile)
    
  } else {
    stop("Error: This function currently only supports downloads from Github or Zenodo")
  }
}

#' Read a single Mosquito Alert JSON file (internal helper)
#'
#' @param file_path String. Path to the .json file to read.
#' @returns A tibble containing the flattened data for that file (year).
#' @keywords internal
read_malert_json <- function(file_path) {
  # Skip if file doesn't exist (e.g., future years)
  if (!file.exists(file_path)) {
    return(NULL)
  }
  
  # Parse data using RcppSimdJson for performance
  parsed_data <- tryCatch({
    RcppSimdJson::fload(file_path, max_simplify_lvl = "data_frame")
  }, error = function(e) {
    warning("RcppSimdJson failed for file ", basename(file_path), ": ", e$message,
            ". Falling back to jsonlite.")
    return(jsonlite::fromJSON(file_path, flatten = TRUE))
  })
  
  # Convert nested list-columns to data frames for flattening
  struct_cols <- c("movelab_annotation", "movelab_annotation_euro",
                   "tiger_responses_text", "site_responses_text",
                   "tiger_responses", "site_responses")
  
  for (col in struct_cols) {
    if (!col %in% names(parsed_data)) next
    val <- parsed_data[[col]]
    # Check if list column or already dataframe (RcppSimdJson sometimes returns DF)
    if (!is.list(val) || is.data.frame(val)) next
    
    # Identify empty elements efficiently
    is_empty <- lengths(val) == 0
    first_valid_idx <- which(!is_empty)[1]
    
    if (is.na(first_valid_idx)) {
      # All elements are empty; replace with NA so flatten ignores them
      parsed_data[[col]] <- NA
      next
    }
    
    first_valid <- val[[first_valid_idx]]
    if (is.data.frame(first_valid)) next
    
    # Get schema from first valid element
    schema <- names(first_valid)
    na_row <- setNames(as.list(rep(NA, length(schema))), schema)
    
    # Fill strictly empty elements with NA rows
    if (any(is_empty)) {
       val[is_empty] <- list(na_row)
    }
    
    # Handle elements that are list(integer(0)) or similar nested empty structures
    is_all_nulls <- vapply(val, function(x) length(x) > 0 && all(lengths(x) == 0), logical(1))
    if (any(is_all_nulls)) {
       val[is_all_nulls] <- list(na_row)
    }
    
    # Use rbindlist for fast binding of the list column
    result <- data.table::rbindlist(val, fill = TRUE, use.names = TRUE)
    
    # Convert data.table to data.frame in-place
    data.table::setDF(result)
    parsed_data[[col]] <- result
  }
  
  # Apply jsonlite::flatten() to expand nested data frame columns
  flattened_data <- jsonlite::flatten(parsed_data)
  
  # Cleanup: Remove parent struct columns that shouldn't appear in final output
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
  
  dplyr::as_tibble(flattened_data)
}
