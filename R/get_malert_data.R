#' Download Mosquito Alert report data from GitHub or Zenodo
#'
#' @param source String. Source to download from. Options are "github" or "zenodo".
#'   If a local file path to a zip archive is provided (e.g., a previously cached
#'   "all_reports.zip"), it will be used directly without downloading.
#' @param doi String. Zenodo DOI if downloading from Zenodo. Default is the
#'   doi that will always point to the most recent version: 10.5281/zenodo.597466.
#' @param cache_path String. Optional path to save the downloaded zip file.
#' @param parallel Controls parallel execution. Options are:
#'   \itemize{
#'     \item **`"auto"` (default):** Automatically detects and uses a configured
#'       `mirai` backend if one is available. If not, runs sequentially.
#'     \item **`TRUE`:** Forces parallel execution. Throws an error if no `mirai`
#'       daemons are configured.
#'     \item **`FALSE`:** Forces sequential execution.
#'   }
#'   For parallelism, you must configure a backend *before* calling this function,
#'   for example: `mirai::daemons(2)`. Note that the optimal number of daemons
#'   is typically 2-4; returns are diminishing after that directly due to the
#'   overhead of spinning up workers and data transfer.
#' @param quiet Logical. If `TRUE`, suppresses progress messages and bar. Default is `FALSE`.
#' @returns A tibble.
#' @export
#' @examples
#' \dontrun{
#' # Standard download from GitHub (with progress bar)
#' malert_reports = get_malert_data(source = "github")
#'
#' # Silent execution
#' malert_reports = get_malert_data(source = "github", quiet = TRUE)
#'
#' # Download and cache locally
#' malert_reports = get_malert_data(source = "github", cache_path = "all_reports.zip")
#'
#' # Use cached file directly
#' malert_reports = get_malert_data(source = "all_reports.zip")
#'
#' # Use legacy reading engine (for compatibility, but 5-10x slower)
#' malert_reports = get_malert_data(source = "github", read_engine = "jsonlite")
#'
#' # Use parallel processing (auto-detected if mirai daemons set)
#' mirai::daemons(2)
#' malert_reports = get_malert_data(source = "github")
#' mirai::daemons(0) # Shut down daemons when done
#' }
get_malert_data = function(
  source = "zenodo",
  doi = "10.5281/zenodo.597466",
  cache_path = NULL,
  read_engine = "RcppSimdJson",
  parallel = "auto",
  quiet = FALSE
) {
  if (!read_engine %in% c("RcppSimdJson", "jsonlite")) {
    stop("read_engine must be either 'RcppSimdJson' or 'jsonlite'")
  }

  # Determine if source is already a file path or a keyword
  is_file_source <- file.exists(source) &&
    !tolower(source) %in% c("github", "zenodo")

  if (is_file_source) {
    zip_path <- source
  } else {
    # It's a keyword source, check cache first
    if (!is.null(cache_path) && file.exists(cache_path)) {
      if (!quiet) {
        message("Using cached file: ", cache_path)
      }
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

  years <- 2014:lubridate::year(lubridate::today())
  n_years <- length(years)

  if (!quiet) {
    message("Reading ", n_years, " files...")
  }

  # Define the reading function based on engine choice
  reader_func <- if (read_engine == "RcppSimdJson") {
    read_malert_json_RcppSimdJson
  } else {
    read_malert_json_jsonlite
  }

  # Prepare file list
  file_list <- file.path(
    temp_extract_dir,
    "home/webuser/webapps/tigaserver/static",
    paste0("all_reports", years, ".json")
  )

  # Determine if parallel processing should be used
  use_parallel <- should_use_parallel(parallel)

  list_of_dfs <- if (use_parallel) {
    if (!quiet) {
      message("Parallel backend detected (mirai). Processing in parallel...")
    }

    # Run Map
    map_res <- mirai::mirai_map(
      file_list,
      function(x, .reader, .col_order_func) {
        requireNamespace("RcppSimdJson", quietly = TRUE)
        requireNamespace("jsonlite", quietly = TRUE)
        requireNamespace("data.table", quietly = TRUE)
        requireNamespace("dplyr", quietly = TRUE)

        # Ensure helper function is available in worker environment
        # This is needed because workers might not have the package loaded (e.g. devtools::load_all context)
        assign(
          "get_expected_column_order",
          .col_order_func,
          envir = globalenv()
        )

        .reader(x)
      },
      .args = list(
        .reader = reader_func,
        .col_order_func = get_expected_column_order
      )
    )

    # Collect results (with progress bar if requested)
    if (quiet) {
      map_res[]
    } else {
      map_res[.progress]
    }
  } else {
    # Sequential with progress bar
    reports_list <- vector("list", n_years)

    for (i in seq_along(years)) {
      this_year <- years[i]

      # Custom progress display
      if (!quiet) {
        console_width <- getOption("width")
        bar_len <- max(5, console_width - 25)
        pct <- floor((i / n_years) * 100)
        n_bars <- floor((i / n_years) * bar_len)
        bar_str <- paste0(
          paste(rep("=", n_bars), collapse = ""),
          paste(rep(" ", bar_len - n_bars), collapse = "")
        )
        cat(sprintf("\r[%s] %3d%% Reading %s...", bar_str, pct, this_year))
      }

      reports_list[[i]] <- reader_func(file_list[i])
    }

    if (!quiet) {
      cat("\n")
    } # Done
    reports_list
  }

  reports <- dplyr::bind_rows(list_of_dfs)

  return(reports)
}
