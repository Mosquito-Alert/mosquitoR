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
    zip_candidates <- list.files(
      zenodo_temp_dir,
      pattern = "\\.zip$",
      recursive = TRUE,
      full.names = TRUE
    )

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

    outer_file_name <- unzip(zenodo_zip, exdir = zenodo_temp_dir, list = TRUE)[
      1,
      1
    ]
    unzip(zenodo_zip, exdir = zenodo_temp_dir)

    reports_zip <- file.path(
      zenodo_temp_dir,
      outer_file_name,
      "all_reports.zip"
    )

    if (!file.exists(reports_zip)) {
      stop("Could not find 'all_reports.zip' in the Zenodo archive.")
    }

    file.copy(reports_zip, destfile, overwrite = TRUE)
    return(destfile)
  } else {
    stop(
      "Error: This function currently only supports downloads from Github or Zenodo"
    )
  }
}

#' Read a single Mosquito Alert JSON file using RcppSimdJson (internal helper)
#'
#' @param file_path String. Path to the .json file to read.
#' @returns A tibble containing the flattened data for that file (year).
#' @keywords internal
read_malert_json_RcppSimdJson <- function(file_path) {
  # Skip if file doesn't exist (e.g., future years)
  if (!file.exists(file_path)) {
    return(NULL)
  }

  # Parse data using RcppSimdJson for performance
  parsed_data <- tryCatch(
    {
      RcppSimdJson::fload(file_path, max_simplify_lvl = "data_frame")
    },
    error = function(e) {
      warning(
        "RcppSimdJson failed for file ",
        basename(file_path),
        ": ",
        e$message,
        ". Falling back to jsonlite."
      )
      # Fallback to jsonlite if RcppSimdJson fails (e.g. malformed JSON)
      return(jsonlite::fromJSON(file_path, flatten = TRUE))
    }
  )

  # Convert nested list-columns to data frames for flattening
  struct_cols <- c(
    "movelab_annotation",
    "movelab_annotation_euro",
    "tiger_responses_text",
    "site_responses_text",
    "tiger_responses",
    "site_responses"
  )

  for (col in struct_cols) {
    if (!col %in% names(parsed_data)) {
      next
    }
    val <- parsed_data[[col]]
    # Check if list column or already dataframe (RcppSimdJson sometimes returns DF)
    if (!is.list(val) || is.data.frame(val)) {
      next
    }

    # Identify empty elements efficiently
    is_empty <- lengths(val) == 0
    first_valid_idx <- which(!is_empty)[1]

    if (is.na(first_valid_idx)) {
      # All elements are empty; replace with NA so flatten ignores them
      parsed_data[[col]] <- NA
      next
    }

    first_valid <- val[[first_valid_idx]]
    if (is.data.frame(first_valid)) {
      next
    }

    # Get schema from first valid element
    schema <- names(first_valid)
    na_row <- setNames(as.list(rep(NA, length(schema))), schema)

    # Fill strictly empty elements with NA rows
    if (any(is_empty)) {
      val[is_empty] <- list(na_row)
    }

    # Handle elements that are list(integer(0)) or similar nested empty structures
    # This checks if all nested elements within a list element have zero length
    is_all_nulls <- vapply(
      val,
      function(x) length(x) > 0 && all(lengths(x) == 0),
      logical(1)
    )
    if (any(is_all_nulls)) {
      val[is_all_nulls] <- list(na_row)
    }

    # Handle elements where individual columns have zero-length vectors
    # This prevents "Column X of item Y is length 0" warnings from rbindlist
    for (i in seq_along(val)) {
      if (!is.list(val[[i]]) || length(val[[i]]) == 0) {
        next
      }
      # Check each column in this element for zero-length vectors
      has_zero_length_col <- any(lengths(val[[i]]) == 0)
      if (has_zero_length_col) {
        # Replace this entire element with NA row
        val[[i]] <- na_row
      }
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
    if (
      col %in% names(flattened_data) && is.data.frame(flattened_data[[col]])
    ) {
      flattened_data[[col]] <- NULL
    }
  }

  # site_responses becomes logical NA column per original jsonlite behavior
  # when it's an empty data.frame with 0 columns
  if (
    "site_responses" %in%
      names(flattened_data) &&
      is.data.frame(flattened_data$site_responses) &&
      ncol(flattened_data$site_responses) == 0
  ) {
    flattened_data$site_responses <- NA
  }

  # Fix type mismatches: Ensure site_certainty_category columns are integer
  # (RcppSimdJson may create logical NA instead of integer NA for NULL values)
  if ("movelab_annotation.site_certainty_category" %in% names(flattened_data)) {
    flattened_data$movelab_annotation.site_certainty_category <-
      as.integer(flattened_data$movelab_annotation.site_certainty_category)
  }
  if (
    "movelab_annotation_euro.site_certainty_category" %in% names(flattened_data)
  ) {
    flattened_data$movelab_annotation_euro.site_certainty_category <-
      as.integer(flattened_data$movelab_annotation_euro.site_certainty_category)
  }

  # Reorder columns to match jsonlite output
  # This is done per-file (before bind_rows) for better performance than
  # reordering the full combined dataset
  expected_col_order <- get_expected_column_order()
  current_names <- names(flattened_data)
  existing_ordered <- intersect(expected_col_order, current_names)
  remaining_cols <- setdiff(current_names, expected_col_order)
  final_order <- c(existing_ordered, remaining_cols)

  # Only reorder if necessary
  if (!identical(current_names, final_order)) {
    flattened_data <- flattened_data[, final_order, drop = FALSE]
  }

  dplyr::as_tibble(flattened_data)
}

#' Get expected column order for Mosquito Alert data (internal helper)
#'
#' Returns the reference column order that matches jsonlite::fromJSON output.
#' Used to ensure RcppSimdJson backend produces identical column order.
#'
#' @returns Character vector of column names in the expected order.
#' @keywords internal
#' @noRd
get_expected_column_order <- function() {
  c(
    "version_UUID",
    "creation_time",
    "creation_date",
    "creation_day_since_launch",
    "creation_year",
    "creation_month",
    "site_cat",
    "type",
    "lon",
    "lat",
    "location_is_masked",
    "tigaprob_cat",
    "latest_version",
    "visible",
    "n_photos",
    "final_expert_status_text",
    "responses",
    "country",
    "updated_at",
    "datetime_fix_offset",
    "point",
    "nuts_2",
    "nuts_3",
    "cached_visible",
    "session",
    "movelab_annotation.edited_user_notes",
    "movelab_annotation.photo_html",
    "movelab_annotation.tiger_certainty_category",
    "movelab_annotation.aegypti_certainty_category",
    "movelab_annotation.score",
    "movelab_annotation.classification",
    "movelab_annotation.site_certainty_category",
    "movelab_annotation_euro.edited_user_notes",
    "movelab_annotation_euro.photo_html",
    "movelab_annotation_euro.class_name",
    "movelab_annotation_euro.class_label",
    "movelab_annotation_euro.class_id",
    "movelab_annotation_euro.class_value",
    "movelab_annotation_euro.site_certainty_category",
    "tiger_responses.q1_response",
    "tiger_responses.q2_response",
    "tiger_responses.q3_response",
    "tiger_responses_text.¿Es pequeño y negro con rayas blancas?",
    "tiger_responses_text.¿Tiene una raya blanca en la cabeza y en el tórax?",
    "tiger_responses_text.¿Tiene rayas blancas en el abdomen y en las patas?",
    "tiger_responses_text.És petit i negre amb ratlles blanques?",
    "tiger_responses_text.Té una ratlla blanca al cap i al tòrax?",
    "tiger_responses_text.Té ratlles blanques a l'abdomen i a les potes?",
    "tiger_responses_text.Is it small and black with white stripes?",
    "tiger_responses_text.Does it have a white stripe on the head and thorax?",
    "tiger_responses_text.Does it have white stripes on the abdomen and legs?",
    "site_responses.q1_response",
    "site_responses.q2_response",
    "site_responses_text.Tipo de lugar de cría",
    "site_responses_text.¿Contiene agua estancada?",
    "site_responses_text.¿Contiene larvas o pupas de mosquito (de cualquier especie)?",
    "site_responses_text.Have you seen mosquito larvae (not necessarily tiger mosquito) inside?",
    "site_responses_text.Type of breeding site",
    "site_responses_text.Does it have stagnant water inside?",
    "site_responses_text.Conté larves o pupes de mosquit (de qualsevol espècie)?",
    "site_responses_text.Selecciona lloc de cria",
    "site_responses_text.Conté aigua estancada?",
    "site_responses.q1_response_new",
    "site_responses.q2_response_new",
    "site_responses.q3_response_new",
    "site_responses_text.¿Has visto mosquitos cerca (a <10 metros)?",
    "site_responses_text.¿Se encuentra en la vía pública?",
    "site_responses_text.Contiene agua estancada y/o larvas o pupas de mosquito (cualquier especie)?",
    "site_responses_text.Is it in a public area?",
    "site_responses_text.Does it contain stagnant water and/or mosquito larvae or pupae (any mosquito species)?",
    "site_responses_text.Have you seen adult mosquitoes nearby (<10 meters)?",
    "site_responses_text.Has vist mosquits a prop (a <10metres)?",
    "site_responses_text.Es troba a la via pública?",
    "site_responses_text.Conté aigua estancada y/o larves o pupes de mosquit (qualsevol espècie)?",
    "tiger_responses_text.¿Cómo es tu mosquito? Consulta el botón (i) y selecciona una respuesta:",
    "tiger_responses_text.¿Cómo es el tórax de tu mosquito? Consulta el botón (i) y selecciona una respuesta:",
    "tiger_responses_text.¿Cómo es el abdomen de tu mosquito? Consulta el botón (i) y selecciona una respuesta:",
    "tiger_responses_text.What does your mosquito look like? Check the (i) button and select an answer:",
    "tiger_responses_text.What does the thorax of your mosquito look like? Check the (i) button and select an answer:",
    "tiger_responses_text.What does the abdomen of your mosquito look like? Check the (i) button and select an answer:",
    "tiger_responses_text.De quin color és? Consulta el botó (i) i selecciona una resposta:",
    "tiger_responses_text.Mira just després del seu cap, al tòrax. Té una sola línia blanca? Consulta el botó (i) i selecciona una resposta:",
    "tiger_responses_text.Com és l'abdomen del mosquit? Consulta el botó (i) i selecciona una resposta:",
    "tiger_responses_text.Com és el teu mosquit? Consulta el botó (i) i selecciona una resposta:",
    "tiger_responses_text.Com és el tòrax del teu mosquit? Consulta el botó (i) i selecciona una resposta:",
    "tiger_responses_text.Com és l'abdomen del teu mosquit? Consulta el botó (i) i selecciona una resposta:",
    "tiger_responses_text.¿De qué color es? Consulta el botón (i) y selecciona una respuesta:",
    "tiger_responses_text.Mira justo después de su cabeza, en el tórax. ¿Tiene una sola línea blanca? Consulta el botón (i) y selecciona una respuesta:",
    "tiger_responses_text.¿Cómo es el abdomen del mosquito? Consulta el botón (i) y selecciona una respuesta:",
    "tiger_responses_text.What color is your mosquito? Check the (i) button and select an answer:",
    "tiger_responses_text.Look right after the head, at the thorax. Does it have a single white line? Check the (i) button and select an answer:",
    "tiger_responses_text.你的蚊子是什麼顏色？檢查(i)按鈕，然後選擇一個答案：",
    "tiger_responses_text.蚊子的胸部是什麼樣子？是否帶有一條白色條紋？檢查(i)按鈕，然後選擇答案：",
    "tiger_responses_text.蚊子的腹部是什麼樣子？檢查(i)按鈕，然後選擇一個答案：",
    "site_responses_text.Conté aigua estancada i/o larves o pupes de mosquit (qualsevol espècie)?",
    "site_responses_text.¿Es un imbornal o alcantarilla?",
    "site_responses_text.¿Has visto mosquitos cerca (a menos de 10 metros)?",
    "site_responses_text.¿Contiene agua estancada y/o larvas de mosquito?",
    "site_responses_text.És un embornal o claveguera?",
    "site_responses_text.Conté aigua estancada i/o larves de mosquit?",
    "site_responses_text.Has vist mosquits a prop (a menys de 10 metres)?",
    "site_responses_text.Is this a storm drain or sewer?",
    "site_responses_text.Have you seen mosquitoes nearby (<10 meters)?",
    "site_responses_text.Does it contain stagnant water and/or mosquito larvae?",
    "site_responses_text.這繁殖地是否排水渠或下水道？",
    "site_responses_text.你有否在周遭地方見到成年蚊子(少於十米內)？",
    "site_responses_text.這繁殖地是否公共空間？",
    "site_responses_text.這繁殖地有沒有藏有積水，和/或任何蚊子品種旳幼蟲或蛹？",
    "tiger_responses_text.question_6",
    "tiger_responses_text.¿Como era el mosquito?",
    "tiger_responses_text.question_13",
    "tiger_responses_text.question_7",
    "site_responses_text.question_12",
    "site_responses_text.question_10",
    "tiger_responses_text.question_1",
    "tiger_responses_text.question_2",
    "tiger_responses_text.question_4",
    "tiger_responses_text.question_5",
    "tiger_responses_text.question_3",
    "site_responses_text.question_17",
    "site_responses_text.question_6",
    "site_responses_text.question_13",
    "site_responses",
    "site_responses_text"
  )
}

#' Read a single Mosquito Alert JSON file using jsonlite (internal helper with previous behavior)
#'
#' @param file_path String. Path to the .json file to read.
#' @returns A tibble containing the flattened data for that file (year).
#' @keywords internal
read_malert_json_jsonlite <- function(file_path) {
  # Skip if file doesn't exist (e.g., future years)
  if (!file.exists(file_path)) {
    return(NULL)
  }

  # Legacy jsonlite implementation
  # jsonlite::fromJSON(unz(temp, file = this_file), flatten = TRUE) %>% as_tibble()
  # Note: The original code used unz() because it was reading directly from the zip.
  # Since we are now extracting the files first (even in the legacy path logic of get_malert_data),
  # we can just read the file directly.

  dplyr::as_tibble(jsonlite::fromJSON(file_path, flatten = TRUE))
}

#' Check if parallel processing should be used
#'
#' @param parallel_arg The value of the `parallel` argument ("auto", TRUE, or FALSE).
#' @return Logical. TRUE if parallel processing should be used, FALSE otherwise.
#' @keywords internal
#' @noRd
should_use_parallel <- function(parallel_arg) {
  # 1. Validate argument
  if (!is.logical(parallel_arg) && !is.character(parallel_arg)) {
    stop("Argument 'parallel' must be 'auto', TRUE, or FALSE.", call. = FALSE)
  }
  if (is.character(parallel_arg) && parallel_arg != "auto") {
    stop("If 'parallel' is a string, it must be 'auto'.", call. = FALSE)
  }

  # 2. Handle explicit FALSE
  if (isFALSE(parallel_arg)) {
    return(FALSE)
  }

  # 3. Check for mirai package
  if (!check_mirai_installed()) {
    if (isTRUE(parallel_arg)) {
      stop(
        "Parallel execution requested (parallel = TRUE), but the 'mirai' package is not installed.\n",
        "Please install it with install.packages('mirai').",
        call. = FALSE
      )
    }
    # For "auto", fallback gracefully
    return(FALSE)
  }

  # 4. Check for active daemons
  # mirai::status()$connections returns the number of active connections
  n_daemons <- check_mirai_daemons()

  if (is.null(n_daemons) || n_daemons == 0) {
    if (isTRUE(parallel_arg)) {
      stop(
        "Parallel execution requested (parallel = TRUE), but no 'mirai' daemons are active.\n",
        "Please configure a backend before calling this function, e.g.:\n",
        "  mirai::daemons(4)",
        call. = FALSE
      )
    }
    # For "auto", fallback gracefully
    return(FALSE)
  }

  return(TRUE)
}

#' Check active mirai daemons (internal helper for testing)
#'
#' @return Integer number of active connections
#' @keywords internal
#' @noRd
check_mirai_daemons <- function() {
  tryCatch(
    mirai::status()$connections,
    error = function(e) 0
  )
}

#' Check if mirai is installed (internal helper for testing)
#'
#' @return Logical
#' @keywords internal
#' @noRd
check_mirai_installed <- function() {
  requireNamespace("mirai", quietly = TRUE)
}
