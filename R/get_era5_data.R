#' Download ERA5 climate data from the Copernicus Climate Data Store
#'
#' @param country_iso3 character. ISO3 country code (e.g., "BGD", "ESP", "USA"). Takes precedence over `bounding_box`.
#' @param bounding_box numeric(4). c(north, west, south, east) in decimal degrees. Ignored if `country_iso3` is provided.
#' @param output_dir character. Directory where downloaded files will be saved. Default "data/output".
#' @param dataset character. One of "reanalysis-era5-single-levels" or "reanalysis-era5-land".
#' @param variables character(). ERA5 variable short names. Default common surface vars.
#' @param start_year integer. Starting year. Default = current year.
#' @param end_year integer. Ending year. Default = current year.
#' @param ecmwfr_key character or NULL. If provided and `write_key = TRUE`, it will be saved via `wf_set_key()`.
#'   If NULL, will try `Sys.getenv("CDS_API_KEY")`. Otherwise requires a pre-existing keyring entry.
#' @param ecmwfr_user character. Keyring label to use with ecmwfr. Default "ecmwfr".
#' @param write_key logical. Persist `ecmwfr_key` to the keyring (off by default for public packages).
#' @param data_format character. "grib" or "netcdf". Default "grib".
#' @param hours character(). Hours like "00:00"…"23:00". Default all 24 hours.
#' @param skip_if_exists_mb numeric. Skip downloads if an existing file is larger than this size (MB). Default 1.
#' @param retry integer. Retries per file on transient errors. Default 2.
#' @param pause_sec numeric. Seconds to wait between retries. Default 10.
#' @param verbose logical. Pass to `wf_request(verbose=)`. Default FALSE.
#'
#' @return A list with `summary` (counts/paths) and `files` (data.frame of per-file results).
#' @importFrom ecmwfr wf_request wf_set_key wf_get_key wf_datasets
#' @export
#' @examples
#' \dontrun{
#' # Using a country code (tries Natural Earth if get_bounding_boxes() not available)
#' get_era5_data(country_iso3 = "BGD", start_year = 2024, end_year = 2024)
#'
#' # Using a custom bounding box
#' get_era5_data(bounding_box = c(26.995, 86.950, 20.204, 93.500),
#'               variables = "2m_temperature", start_year = 2024, end_year = 2024)
#' }
get_era5_data <- function(
  country_iso3 = NULL,
  bounding_box = NULL,
  output_dir = "data/output",
  dataset = "reanalysis-era5-single-levels",
  variables = c("2m_dewpoint_temperature","2m_temperature",
                "10m_u_component_of_wind","10m_v_component_of_wind",
                "surface_pressure","total_precipitation"),
  start_year = as.integer(format(Sys.Date(), "%Y")),
  end_year   = as.integer(format(Sys.Date(), "%Y")),
  ecmwfr_key = NULL,
  ecmwfr_user = "ecmwfr",
  write_key = FALSE,
  data_format = c("grib","netcdf"),
  hours = sprintf("%02d:00", 0:23),
  skip_if_exists_mb = 1,
  retry = 2,
  pause_sec = 10,
  verbose = FALSE
) {
  # ---- validate & normalize ----
  data_format <- match.arg(tolower(data_format), c("grib","netcdf"))
  if (is.null(country_iso3) && is.null(bounding_box)) {
    stop("Either `country_iso3` or `bounding_box` must be provided.")
  }
  cy <- as.integer(format(Sys.Date(), "%Y"))
  if (start_year > end_year) stop("`start_year` must be <= `end_year`.")
  end_year <- min(end_year, cy)

  # Dataset exists?
  ds <- try(ecmwfr::wf_datasets(), silent = TRUE)
  if (!inherits(ds, "try-error")) {
    if (!dataset %in% ds$name) {
      stop(sprintf("Dataset '%s' not found in wf_datasets(). Check spelling or update ecmwfr.", dataset))
    }
  }

  # ---- resolve bounding box ----
  if (!is.null(country_iso3)) {
    # Try user-provided helper if present
    if (exists("get_bounding_boxes", mode = "function")) {
      bbox_result <- get_bounding_boxes(countries = country_iso3, format = "vector")
      if (is.null(bbox_result) || length(bbox_result) == 0) {
        stop(sprintf("Country code '%s' not found by get_bounding_boxes().", country_iso3))
      }
      bounding_box <- bbox_result[[1]]
    } else {
      # Fallback: rnaturalearth + sf
      if (!requireNamespace("rnaturalearth", quietly = TRUE) ||
          !requireNamespace("sf", quietly = TRUE)) {
        stop("Provide `bounding_box` or install {rnaturalearth} and {sf} to look up ISO3 bounding boxes.")
      }
      world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
      row <- world[world$iso_a3 == country_iso3, ]
      if (nrow(row) == 0) stop(sprintf("ISO3 '%s' not found in Natural Earth.", country_iso3))
      bb <- sf::st_bbox(row$geometry)
      # CDS expects N/W/S/E
      bounding_box <- c(north = as.numeric(bb["ymax"]),
                        west  = as.numeric(bb["xmin"]),
                        south = as.numeric(bb["ymin"]),
                        east  = as.numeric(bb["xmax"]))
    }
    message(sprintf("Using bounding box for %s: [N=%.4f, W=%.4f, S=%.4f, E=%.4f]",
                    country_iso3, bounding_box[1], bounding_box[2], bounding_box[3], bounding_box[4]))
  } else {
    if (length(bounding_box) != 4 || !is.numeric(bounding_box))
      stop("`bounding_box` must be numeric(4): c(north, west, south, east).")
  }
  area_str <- paste(as.numeric(bounding_box), collapse = "/") # N/W/S/E

  # ---- auth: env -> optional persist -> ensure key exists ----
  if (is.null(ecmwfr_key)) {
    env_key <- Sys.getenv("CDS_API_KEY", unset = "")
    if (nzchar(env_key)) ecmwfr_key <- env_key
  }
  if (!is.null(ecmwfr_key) && isTRUE(write_key)) {
    ecmwfr::wf_set_key(key = ecmwfr_key, user = ecmwfr_user)
  }
  # best-effort unlock (linux)
  if (requireNamespace("keyring", quietly = TRUE)) {
    if (isTRUE(try(keyring::keyring_is_locked(), silent = TRUE))) {
      try(keyring::keyring_unlock(), silent = TRUE)
    }
  }
  if (is.null(ecmwfr::wf_get_key(ecmwfr_user))) {
    stop(
      sprintf("No CDS token found for user '%s'. ", ecmwfr_user),
      "Set it once with ecmwfr::wf_set_key(key = '<YOUR_TOKEN>', user = '", ecmwfr_user, "') ",
      "or export CDS_API_KEY and call get_era5_data(write_key = TRUE) to persist."
    )
  }

  # ---- paths & helpers ----
  output_dir <- path.expand(output_dir)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  size_threshold <- skip_if_exists_mb * 1024 * 1024
  requires_product_type <- identical(dataset, "reanalysis-era5-single-levels")

  days_in_month <- function(yy, mm) {
    start <- as.Date(sprintf("%04d-%02d-01", yy, mm))
    end   <- seq(start, by = "month", length.out = 2)[2] - 1
    format(seq(start, end, by = "day"), "%d")
  }

  # ---- stats/results ----
  total <- existed <- downloaded <- failed <- 0L
  rows <- list()
  ext <- ifelse(data_format == "grib", "grib", "nc")

  message(sprintf("Starting ERA5 downloads %d–%d (%s, %s)", start_year, end_year, dataset, data_format))

  # ---- main loop ----
  for (yy in start_year:end_year) {
    months <- if (yy == cy) 1:as.integer(format(Sys.Date(), "%m")) else 1:12

    for (mm in months) {
      mm_str  <- sprintf("%02d", mm)
      day_vec <- days_in_month(yy, mm)

      for (var in variables) {
        filename <- sprintf("era5_%d_%s_%s.%s", yy, mm_str, var, ext)
        filepath <- file.path(output_dir, filename)
        total <- total + 1L

        if (file.exists(filepath) && file.size(filepath) > size_threshold) {
          existed <- existed + 1L
          rows[[length(rows)+1]] <- data.frame(
            file = filename, year = yy, month = mm, variable = var,
            status = "exists", bytes = file.size(filepath),
            request_id = NA_character_, stringsAsFactors = FALSE
          )
          next
        }

        req <- list(
          dataset_short_name = dataset,
          variable           = var,
          year               = as.character(yy),
          month              = mm_str,
          day                = day_vec,
          time               = hours,
          area               = area_str,      # N/W/S/E
          data_format        = data_format,
          target             = filename
        )
        if (requires_product_type) req$product_type <- "reanalysis"

        attempt <- 0L; ok <- FALSE; rid <- NA_character_
        repeat {
          attempt <- attempt + 1L
          res <- try(
            ecmwfr::wf_request(
              user     = ecmwfr_user,
              request  = req,
              transfer = TRUE,
              path     = output_dir,
              time_out = 3600,
              verbose  = verbose
            ),
            silent = TRUE
          )
          if (!inherits(res, "try-error")) { ok <- TRUE; rid <- as.character(res); break }
          if (attempt > retry) break
          Sys.sleep(pause_sec)
        }

        if (ok && file.exists(filepath) && file.size(filepath) > size_threshold) {
          downloaded <- downloaded + 1L
          rows[[length(rows)+1]] <- data.frame(
            file = filename, year = yy, month = mm, variable = var,
            status = "downloaded", bytes = file.size(filepath),
            request_id = rid, stringsAsFactors = FALSE
          )
        } else {
          failed <- failed + 1L
          rows[[length(rows)+1]] <- data.frame(
            file = filename, year = yy, month = mm, variable = var,
            status = "failed",
            bytes = if (file.exists(filepath)) file.size(filepath) else NA_integer_,
            request_id = rid, stringsAsFactors = FALSE
          )
          if (verbose && inherits(res, "try-error")) {
            message(sprintf("Failure detail for %s: %s", filename, tryCatch(conditionMessage(res), error = function(...) "No message")))
          }
        }
      }
    }
  }

  files_df <- if (length(rows)) do.call(rbind, rows) else
    data.frame(file=character(), year=integer(), month=integer(), variable=character(),
               status=character(), bytes=integer(), request_id=character(), stringsAsFactors = FALSE)

  summary <- list(
    total_files_needed   = total,
    files_already_exist  = existed,
    files_downloaded     = downloaded,
    files_failed         = failed,
    success_rate         = if (total > 0) (existed + downloaded) / total * 100 else NA_real_,
    output_directory     = output_dir
  )

  list(summary = summary, files = files_df)
}
