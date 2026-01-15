#' Download Mosquito Alert report data from GitHub or Zenodo
#'
#' @param source String. Source to download from. Options are "github" or "zenodo".
#'   If a local file path to a zip archive is provided (e.g., a previously cached "all_reports.zip"), it will be used directly without downloading.
#' @param doi String. Zenodo DOI if downloading from Zenodo. Default is the doi that will always point to the most recent version: 10.5281/zenodo.597466.
#' @param cache_path String. Optional path to save the downloaded zip file.
#'   If provided and the file exists, it will be used instead of re-downloading.
#'   If `NULL` (default), the downloaded zip and extracted data will be stored in a temporary location and removed after extraction.
#' @returns A tibble.
#' @export
#' @examples
#' \dontrun{
#' # Standard download from GitHub
#' malert_reports = get_malert_data(source = "github")
#'
#' # Download and cache locally
#' malert_reports = get_malert_data(source = "github", cache_path = "all_reports.zip")
#'
#' # Use cached file directly
#' malert_reports = get_malert_data(source = "all_reports.zip")
#' }
get_malert_data = function(
  source = "zenodo",
  doi = "10.5281/zenodo.597466",
  cache_path = NULL
) {
  # Determine if source is already a file path or a keyword
  is_file_source <- file.exists(source) &&
    !tolower(source) %in% c("github", "zenodo")

  if (is_file_source) {
    zip_path <- source
  } else {
    # It's a keyword source, check cache first
    if (!is.null(cache_path) && file.exists(cache_path)) {
      message("Using cached file: ", cache_path)
      zip_path <- cache_path
    } else {
      # Need to download
      if (is.null(cache_path)) {
        # Temporary download
        zip_path <- tempfile(fileext = ".zip")
        on.exit(unlink(zip_path), add = TRUE)
      } else {
        # Persistent download
        zip_path <- cache_path
      }

      download_malert_zip(source = source, doi = doi, destfile = zip_path)
    }
  }

  # Create temporary directory for extracted JSON files
  temp_extract_dir <- tempfile(pattern = "malert_json_")
  dir.create(temp_extract_dir)
  on.exit(unlink(temp_extract_dir, recursive = TRUE), add = TRUE)

  # Extract entire zip archive once (more efficient than unz() for each file)
  tryCatch(
    {
      unzip(zip_path, exdir = temp_extract_dir)
    },
    error = function(e) {
      stop("Failed to extract zip archive at ", zip_path, ": ", e$message)
    }
  )

  reports = bind_rows(lapply(
    2014:lubridate::year(lubridate::today()),
    function(this_year) {
      this_file = file.path(
        temp_extract_dir,
        "home/webuser/webapps/tigaserver/static",
        paste0("all_reports", this_year, ".json")
      )

      read_malert_json(this_file)
    }
  ))

  return(reports)
}
