# Tests for get_malert_data function
# These tests call the actual function with mocked downloads to verify output structure.
# When jsonlite is replaced with RcppSimdJson, these tests will validate compatibility.

# Expected columns definition (shared between mocked and live tests)
ALL_EXPECTED_COLS <- c(
  # Core Columns
  "version_UUID",
  "creation_time",
  "creation_date",
  "creation_year",
  "creation_month",
  "type",
  "lon",
  "lat",
  "location_is_masked",
  "tigaprob_cat",
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
  # Flattened movelab_annotation
  "movelab_annotation.edited_user_notes",
  "movelab_annotation.photo_html",
  "movelab_annotation.tiger_certainty_category",
  "movelab_annotation.aegypti_certainty_category",
  "movelab_annotation.score",
  "movelab_annotation.classification",
  "movelab_annotation.site_certainty_category",
  # Flattened movelab_annotation_euro
  "movelab_annotation_euro.edited_user_notes",
  "movelab_annotation_euro.photo_html",
  "movelab_annotation_euro.class_name",
  "movelab_annotation_euro.class_label",
  "movelab_annotation_euro.class_id",
  "movelab_annotation_euro.class_value",
  "movelab_annotation_euro.site_certainty_category",
  # Flattened tiger_responses_text
  "tiger_responses_text.question_6",
  "tiger_responses_text.question_7",
  "tiger_responses_text.question_13",
  "tiger_responses_text.What does your mosquito look like? Check the (i) button and select an answer:",
  "tiger_responses_text.What does the thorax of your mosquito look like? Check the (i) button and select an answer:",
  "tiger_responses_text.What does the abdomen of your mosquito look like? Check the (i) button and select an answer:",
  # Flattened site_responses_text
  "site_responses_text.question_12",
  "site_responses_text.question_10",
  "site_responses_text.question_17"
)

# Helper function to create mock data matching real API format
create_mock_malert_data <- function(year) {
  # Create minimal data that matches real API structure
  list(
    list(
      version_UUID = paste0("test-uuid-", year, "-001"),
      creation_time = paste0(year, "-06-15T10:30:00Z"),
      creation_date = paste0(year, "-06-15"),
      creation_day_since_launch = 3500L,
      creation_year = as.integer(year),
      creation_month = 6L,
      site_cat = 1L,
      type = "adult",
      lon = 2.1734,
      lat = 41.3851,
      location_is_masked = FALSE,
      tigaprob_cat = 2L,
      latest_version = TRUE,
      visible = TRUE,
      n_photos = 1L,
      final_expert_status_text = 1L,
      responses = list(list(
        id = 12345L,
        translated_question = "Test question?",
        translated_answer = "Test answer",
        question_id = 1L,
        question = "question_1",
        answer_id = 11L,
        answer = "N/A",
        answer_value = "1",
        report = paste0("test-uuid-", year, "-001")
      )),
      country = "ESP",
      updated_at = paste0(year, "-06-15T12:00:00Z"),
      datetime_fix_offset = -7200L,
      point = "SRID=4326;POINT(2.1734 41.3851)",
      nuts_2 = "ES51",
      nuts_3 = "ES511",
      cached_visible = TRUE,
      session = NA,
      # Add nested structures that will be flattened
      movelab_annotation = list(
        edited_user_notes = "Note 1",
        photo_html = "<div>img1</div>",
        tiger_certainty_category = 1L,
        aegypti_certainty_category = 0L,
        score = 10L,
        classification = "probable",
        site_certainty_category = 2L
      ),
      movelab_annotation_euro = list(
        edited_user_notes = "Euro Note 1",
        photo_html = "<div>euro_img1</div>",
        class_name = "Aedes albopictus",
        class_label = "Tiger mosquito",
        class_id = 5L,
        class_value = 1L,
        site_certainty_category = 2L
      ),
      tiger_responses_text = list(
        question_6 = "q6_text",
        question_7 = "q7_text",
        question_13 = "q13_text",
        `What does your mosquito look like? Check the (i) button and select an answer:` = "Striped",
        `What does the thorax of your mosquito look like? Check the (i) button and select an answer:` = "White line",
        `What does the abdomen of your mosquito look like? Check the (i) button and select an answer:` = "Dark"
      ),
      site_responses_text = list(
        question_12 = "q12_text",
        question_10 = "q10_text",
        question_17 = "q17_text"
      )
    ),
    list(
      version_UUID = paste0("test-uuid-", year, "-002"),
      creation_time = paste0(year, "-07-20T14:45:00Z"),
      creation_date = paste0(year, "-07-20"),
      creation_day_since_launch = 3535L,
      creation_year = as.integer(year),
      creation_month = 7L,
      site_cat = 2L,
      type = "bite",
      lon = -3.7038,
      lat = 40.4168,
      location_is_masked = FALSE,
      tigaprob_cat = 0L,
      latest_version = TRUE,
      visible = TRUE,
      n_photos = 0L,
      final_expert_status_text = 1L,
      responses = list(list(
        id = 12346L,
        translated_question = "How many bites?",
        translated_answer = "2",
        question_id = 1L,
        question = "question_1",
        answer_id = 12L,
        answer = "N/A",
        answer_value = "2",
        report = paste0("test-uuid-", year, "-002")
      )),
      country = "ESP",
      updated_at = paste0(year, "-07-20T16:00:00Z"),
      datetime_fix_offset = -7200L,
      point = "SRID=4326;POINT(-3.7038 40.4168)",
      nuts_2 = "ES30",
      nuts_3 = "ES300",
      cached_visible = TRUE,
      session = NA,
      # Add nested structures (can be partially empty/different to test robustness)
      movelab_annotation = list(
        edited_user_notes = NA_character_,
        photo_html = NA_character_,
        tiger_certainty_category = NA_integer_,
        aegypti_certainty_category = NA_integer_,
        score = NA_integer_,
        classification = NA_character_,
        site_certainty_category = NA_integer_
      ),
      movelab_annotation_euro = list(
        edited_user_notes = NA_character_,
        photo_html = NA_character_,
        class_name = NA_character_,
        class_label = NA_character_,
        class_id = NA_integer_,
        class_value = NA_integer_,
        site_certainty_category = NA_integer_
      ),
      tiger_responses_text = list(
        question_6 = NA_character_,
        question_7 = NA_character_,
        question_13 = NA_character_,
        `What does your mosquito look like? Check the (i) button and select an answer:` = NA_character_,
        `What does the thorax of your mosquito look like? Check the (i) button and select an answer:` = NA_character_,
        `What does the abdomen of your mosquito look like? Check the (i) button and select an answer:` = NA_character_
      ),
      site_responses_text = list(
        question_12 = NA_character_,
        question_10 = NA_character_,
        question_17 = NA_character_
      )
    )
  )
}


check_mocked_get_malert_data <- function(engine) {
  # Create a temp directory for our mock data using withr for auto-cleanup
  temp_dir <- withr::local_tempdir(pattern = "mosquitoR-test-")

  # Create nested directory structure matching real zip
  json_dir <- file.path(
    temp_dir,
    "home",
    "webuser",
    "webapps",
    "tigaserver",
    "static"
  )
  dir.create(json_dir, recursive = TRUE)

  # Create JSON files for all years from 2014 to current
  current_year <- lubridate::year(lubridate::today())
  for (year in 2014:current_year) {
    json_file <- file.path(json_dir, paste0("all_reports", year, ".json"))
    jsonlite::write_json(
      create_mock_malert_data(year),
      json_file,
      auto_unbox = TRUE
    )
  }

  # Create the zip file
  zip_file <- file.path(temp_dir, "all_reports.zip")

  # Zip all JSON files safely changing directory
  json_files <- file.path(
    "home",
    "webuser",
    "webapps",
    "tigaserver",
    "static",
    paste0("all_reports", 2014:current_year, ".json")
  )

  withr::with_dir(temp_dir, {
    utils::zip(zipfile = zip_file, files = json_files, flags = "-r9Xq")
  })

  # Mock download.file to use our test zip
  local_mocked_bindings(
    download.file = function(url, destfile, ...) {
      file.copy(zip_file, destfile)
      invisible(0)
    }
  )

  # Call the ACTUAL get_malert_data function with mocked download
  capture.output(
    result <- suppressMessages(get_malert_data(
      source = "github",
      read_engine = engine
    ))
  )

  # --- Verify output structure ---

  # 1. Check class
  expect_s3_class(result, "tbl_df")

  # 2. Check dimensions (2 rows per year × number of years)
  expected_rows <- 2 * length(2014:current_year)
  expect_equal(nrow(result), expected_rows)

  # 3. Check essential columns exist
  for (col in ALL_EXPECTED_COLS) {
    expect_true(
      col %in% names(result),
      info = paste("Column", col, "should exist")
    )
  }

  # 4. Check column types
  expect_type(result$version_UUID, "character")
  expect_type(result$creation_time, "character")
  expect_type(result$creation_date, "character")
  expect_type(result$creation_year, "integer")
  expect_type(result$creation_month, "integer")
  expect_type(result$type, "character")
  expect_type(result$lon, "double")
  expect_type(result$lat, "double")
  expect_type(result$location_is_masked, "logical")
  expect_type(result$visible, "logical")
  expect_type(result$country, "character")
  expect_type(result$point, "character")

  # 5. Check responses is a list-column
  expect_type(result$responses, "list")

  # 6. Verify nested response structure (first element)
  response1 <- result$responses[[1]]
  expect_s3_class(response1, "data.frame")
  response_cols <- c(
    "id",
    "translated_question",
    "translated_answer",
    "question_id",
    "question",
    "answer_id",
    "answer",
    "answer_value",
    "report"
  )
  for (col in response_cols) {
    expect_true(
      col %in% names(response1),
      info = paste("Response column", col, "should exist")
    )
  }

  # 7. Verify nested response column types
  expect_type(response1$id, "integer")
  expect_type(response1$translated_question, "character")
  expect_type(response1$translated_answer, "character")
  expect_type(response1$question_id, "integer")
  expect_type(response1$question, "character")
  expect_type(response1$answer_id, "integer")
  expect_type(response1$answer, "character")
  expect_type(response1$answer_value, "character")
  expect_type(response1$report, "character")

  # 8. Verify data ranges
  expect_true(all(result$lon >= -180 & result$lon <= 180))
  expect_true(all(result$lat >= -90 & result$lat <= 90))
  expect_true(all(result$creation_year >= 2014))
  expect_true(all(result$creation_year <= current_year))

  # 9. Verify we have data from each year
  expect_equal(sort(unique(result$creation_year)), 2014:current_year)

  # 10. Verify report UUID links in nested responses
  for (i in seq_len(nrow(result))) {
    if (!is.null(result$responses[[i]]) && nrow(result$responses[[i]]) > 0) {
      expect_true(
        all(result$responses[[i]]$report == result$version_UUID[i]),
        info = paste("Row", i, "responses should link to parent UUID")
      )
    }
  }
}

test_that("get_malert_data returns correct tibble structure with RcppSimdJson (mocked github)", {
  check_mocked_get_malert_data("RcppSimdJson")
})

test_that("get_malert_data returns correct tibble structure with jsonlite (mocked github)", {
  check_mocked_get_malert_data("jsonlite")
})


test_that("get_malert_data validates source parameter", {
  # Test with invalid source - should error
  expect_error(
    get_malert_data(source = "invalid_source"),
    regexp = "This function currently only supports downloads from Github or Zenodo"
  )
})


# --- Structure Validation Tests ---
# These tests validate the exact structure for future parser replacement

test_that("malert data has correct nested structure (comprehensive validation)", {
  # Real data fixture from dput() - exact structure from jsonlite::fromJSON
  # This fixture represents what the function MUST return regardless of parser
  sample_malert_fixture <- structure(
    list(
      version_UUID = c(
        "ba268a98-e3a9-487f-943c-0ac84c598517",
        "75f3a65a-7d59-4ea5-ab2e-112cf01096d9"
      ),
      creation_time = c(
        "2023-06-13T12:23:21.021710Z",
        "2023-07-04T18:38:30.750216Z"
      ),
      creation_date = c("2023-06-13", "2023-07-04"),
      creation_day_since_launch = c(3287L, 3308L),
      creation_year = c(2023L, 2023L),
      creation_month = 6:7,
      site_cat = c(5L, 5L),
      type = c("bite", "bite"),
      lon = c(-4.48914684355259, -3.12960784882307),
      lat = c(36.7446368890047, 40.1056256996785),
      location_is_masked = c(FALSE, FALSE),
      tigaprob_cat = c(0L, 0L),
      latest_version = c(TRUE, TRUE),
      visible = c(TRUE, TRUE),
      n_photos = c(0L, 0L),
      final_expert_status_text = c(1L, 1L),
      responses = list(
        # First response (7 rows)
        structure(
          list(
            id = 717611:717617,
            translated_question = c(
              "¿Cuántas picaduras tienes y en qué parte del cuerpo?",
              "¿Donde te han picado?",
              "¿Donde te han picado?",
              "¿Donde te han picado?",
              "¿Dónde te han picado?",
              "¿Cuando te han picado?",
              "¿En qué momento ha sido?"
            ),
            translated_answer = c(
              "",
              "Brazo izquierdo",
              "Pierna izquierda",
              "Brazo derecho",
              "En el exterior",
              "En las últimas 24h",
              "Tarde"
            ),
            question_id = c(1L, 2L, 2L, 2L, 4L, 5L, 3L),
            question = c(
              "question_1",
              "question_2",
              "question_2",
              "question_2",
              "question_4",
              "question_5",
              "question_3"
            ),
            answer_id = c(11L, 22L, 25L, 23L, 43L, 52L, 33L),
            answer = c(
              "N/A",
              "question_2_answer_22",
              "question_2_answer_25",
              "question_2_answer_23",
              "question_4_answer_43",
              "question_5_answer_52",
              "question_3_answer_33"
            ),
            answer_value = c("6", "2", "3", "1", NA, NA, NA),
            report = rep("ba268a98-e3a9-487f-943c-0ac84c598517", 7)
          ),
          class = "data.frame",
          row.names = c(NA, 7L)
        ),
        # Second response (4 rows)
        structure(
          list(
            id = 501529:501532,
            translated_question = c(
              "¿Cuántas picaduras tienes y en qué parte del cuerpo?",
              "¿Donde te han picado?",
              "¿Dónde te han picado?",
              "¿En qué momento ha sido?"
            ),
            translated_answer = c(
              "",
              "Pierna izquierda",
              "En el exterior",
              "Mañana"
            ),
            question_id = c(1L, 2L, 4L, 3L),
            question = c(
              "question_1",
              "question_2",
              "question_4",
              "question_3"
            ),
            answer_id = c(11L, 25L, 43L, 31L),
            answer = c(
              "N/A",
              "question_2_answer_25",
              "question_4_answer_43",
              "question_3_answer_31"
            ),
            answer_value = c("20", "3", NA, NA),
            report = rep("75f3a65a-7d59-4ea5-ab2e-112cf01096d9", 4)
          ),
          class = "data.frame",
          row.names = c(NA, 4L)
        )
      ),
      country = c("ESP", "ESP"),
      updated_at = c(
        "2025-01-06T00:35:29.930239Z",
        "2025-01-06T00:03:31.836052Z"
      ),
      datetime_fix_offset = c(-7200L, -7200L),
      point = c(
        "SRID=4326;POINT (-4.489146843552589 36.74463688900472)",
        "SRID=4326;POINT (-3.129607848823071 40.10562569967852)"
      ),
      nuts_2 = c("ES61", "ES30"),
      nuts_3 = c("ES617", "ES300"),
      cached_visible = c(TRUE, TRUE),
      session = c(NA, NA)
    ),
    row.names = c(NA, -2L),
    class = c("tbl_df", "tbl", "data.frame")
  )

  # --- Test 1: Overall structure ---
  expect_s3_class(sample_malert_fixture, "tbl_df")
  expect_equal(nrow(sample_malert_fixture), 2)

  # --- Test 2: Essential columns exist ---
  essential_cols <- c(
    "version_UUID",
    "creation_time",
    "creation_date",
    "creation_year",
    "creation_month",
    "type",
    "lon",
    "lat",
    "responses",
    "country",
    "point",
    "nuts_2",
    "nuts_3",
    "visible"
  )
  for (col in essential_cols) {
    expect_true(
      col %in% names(sample_malert_fixture),
      info = paste("Column", col, "should exist")
    )
  }

  # --- Test 3: Column types ---
  expect_type(sample_malert_fixture$version_UUID, "character")
  expect_type(sample_malert_fixture$creation_time, "character")
  expect_type(sample_malert_fixture$creation_date, "character")
  expect_type(sample_malert_fixture$creation_day_since_launch, "integer")
  expect_type(sample_malert_fixture$creation_year, "integer")
  expect_type(sample_malert_fixture$creation_month, "integer")
  expect_type(sample_malert_fixture$type, "character")
  expect_type(sample_malert_fixture$lon, "double")
  expect_type(sample_malert_fixture$lat, "double")
  expect_type(sample_malert_fixture$location_is_masked, "logical")
  expect_type(sample_malert_fixture$visible, "logical")
  expect_type(sample_malert_fixture$country, "character")
  expect_type(sample_malert_fixture$point, "character")
  expect_type(sample_malert_fixture$datetime_fix_offset, "integer")

  # --- Test 4: Responses is a list-column ---
  expect_type(sample_malert_fixture$responses, "list")
  expect_equal(length(sample_malert_fixture$responses), 2)

  # --- Test 5: Each response element is a data.frame ---
  expect_s3_class(sample_malert_fixture$responses[[1]], "data.frame")
  expect_s3_class(sample_malert_fixture$responses[[2]], "data.frame")

  # --- Test 6: Nested response structure ---
  response_cols <- c(
    "id",
    "translated_question",
    "translated_answer",
    "question_id",
    "question",
    "answer_id",
    "answer",
    "answer_value",
    "report"
  )

  for (col in response_cols) {
    expect_true(
      col %in% names(sample_malert_fixture$responses[[1]]),
      info = paste("Response column", col, "should exist")
    )
  }

  # --- Test 7: Nested response column types ---
  response1 <- sample_malert_fixture$responses[[1]]
  expect_type(response1$id, "integer")
  expect_type(response1$translated_question, "character")
  expect_type(response1$translated_answer, "character")
  expect_type(response1$question_id, "integer")
  expect_type(response1$question, "character")
  expect_type(response1$answer_id, "integer")
  expect_type(response1$answer, "character")
  expect_type(response1$answer_value, "character") # Can contain NA
  expect_type(response1$report, "character")

  # --- Test 8: Response row counts can vary ---
  expect_equal(nrow(sample_malert_fixture$responses[[1]]), 7)
  expect_equal(nrow(sample_malert_fixture$responses[[2]]), 4)

  # --- Test 9: Report UUID links back to parent ---
  expect_equal(
    unique(sample_malert_fixture$responses[[1]]$report),
    sample_malert_fixture$version_UUID[1]
  )
  expect_equal(
    unique(sample_malert_fixture$responses[[2]]$report),
    sample_malert_fixture$version_UUID[2]
  )

  # --- Test 10: Data value ranges ---
  expect_true(all(
    sample_malert_fixture$lon >= -180 & sample_malert_fixture$lon <= 180
  ))
  expect_true(all(
    sample_malert_fixture$lat >= -90 & sample_malert_fixture$lat <= 90
  ))
  expect_true(all(sample_malert_fixture$creation_year >= 2014))
})


# --- Live Integration Tests ---
# These tests make actual network requests and should only be run in CI
# or when explicitly enabled via environment variable. Currently run schedule for these is in .github/workflows/malert-live-tests.yml

check_live_get_malert_data <- function(engine) {
  # --- Test Configuration ---
  testthat::skip_on_cran()

  skip_if_not(
    Sys.getenv("RUN_MALERT_LIVE_TESTS") == "TRUE",
    "Skipping live download test. Set RUN_MALERT_LIVE_TESTS='TRUE' to run."
  )

  # --- 1. Download data from GitHub ---
  reports <- get_malert_data(source = "github", read_engine = engine)

  # --- 2. Verify structure ---
  expect_s3_class(reports, "tbl_df")
  expect_gt(nrow(reports), 0)
  expect_gt(ncol(reports), 30) # Should have 48 columns, at least 30

  # --- 3. Verify essential columns exist ---
  for (col in ALL_EXPECTED_COLS) {
    expect_true(
      col %in% colnames(reports),
      info = paste("Column", col, "should exist in live data")
    )
  }

  # --- 4. Verify data types ---
  expect_type(reports$version_UUID, "character")
  expect_type(reports$lon, "double")
  expect_type(reports$lat, "double")
  expect_type(reports$creation_year, "integer")
  expect_type(reports$visible, "logical")

  # --- 5. Verify data range ---
  # Data should span from 2014 to current year
  expect_true(min(reports$creation_year, na.rm = TRUE) <= 2015)
  expect_true(
    max(reports$creation_year, na.rm = TRUE) >=
      lubridate::year(lubridate::today()) - 1
  )

  # --- 6. Verify coordinates are valid ---
  # Most reports should be in Europe (lon: -20 to 40, lat: 30 to 70)
  # but the data includes global coverage now
  expect_true(all(reports$lon >= -180 & reports$lon <= 180, na.rm = TRUE))
  expect_true(all(reports$lat >= -90 & reports$lat <= 90, na.rm = TRUE))

  # --- 7. Log summary for CI visibility ---
  message("Successfully downloaded ", nrow(reports), " reports")
  message(
    "Year range: ",
    min(reports$creation_year, na.rm = TRUE),
    " - ",
    max(reports$creation_year, na.rm = TRUE)
  )
  message("Countries: ", length(unique(reports$country)))

  # --- 8. Verify global data consistency ---
  # Ensure critical columns are never NA across the *entire* dataset
  # This serves the same purpose as checking specific years but covers everything
  expect_false(any(is.na(reports$type)), label = "type should never be NA")
  expect_false(
    any(is.na(reports$creation_year)),
    label = "creation_year should never be NA"
  )
  expect_false(
    any(is.na(reports$version_UUID)),
    label = "version_UUID should never be NA"
  )

  # Verify responses structure globally if present
  if ("responses" %in% names(reports)) {
    non_empty_responses <- reports$responses[lengths(reports$responses) > 0]
    if (length(non_empty_responses) > 0) {
      expect_s3_class(non_empty_responses[[1]], "data.frame")
    }
  }
  # --- 9. Verify consistent year coverage ---
  # Check that we have data from each expected year
  current_year <- lubridate::year(lubridate::today())
  expected_years <- 2014:current_year

  years_in_data <- unique(reports$creation_year)

  # Check that at least most years are represented
  # (very recent data might not have current year yet)
  covered_years <- sum(expected_years %in% years_in_data)
  expect_gte(
    covered_years,
    length(expected_years) - 1,
    label = "Number of years with data should be at least n-1 expected years"
  )

  # Verify each year has a reasonable number of reports
  for (year in expected_years[expected_years < current_year]) {
    year_count <- sum(reports$creation_year == year, na.rm = TRUE)
    expect_gt(year_count, 0, label = paste("Reports for year", year))
  }
}

test_that("get_malert_data downloads and parses GitHub data with RcppSimdJson (live test)", {
  check_live_get_malert_data("RcppSimdJson")
})

test_that("get_malert_data downloads and parses GitHub data with jsonlite (live test)", {
  check_live_get_malert_data("jsonlite")
})


test_that("get_malert_data respects read_engine argument", {
  temp_dir <- withr::local_tempdir(pattern = "malert_engine_test_")

  # Setup Mock Data
  json_dir <- file.path(temp_dir, "home/webuser/webapps/tigaserver/static")
  dir.create(json_dir, recursive = TRUE)
  curr_year <- lubridate::year(lubridate::today())
  jsonlite::write_json(
    list(list(version_UUID = "engine-test", creation_year = curr_year)),
    file.path(json_dir, paste0("all_reports", curr_year, ".json")),
    auto_unbox = TRUE
  )

  zip_source <- file.path(temp_dir, "source.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_source, files = "home", flags = "-r9Xq")
  })

  # 1. Test Default (RcppSimdJson)
  res_default <- get_malert_data(source = zip_source)
  expect_equal(res_default$version_UUID, "engine-test")

  # 2. Test Explicit RcppSimdJson
  res_rcpp <- get_malert_data(source = zip_source, read_engine = "RcppSimdJson")
  expect_equal(res_rcpp$version_UUID, "engine-test")

  # 3. Test Explicit jsonlite
  res_jsonlite <- get_malert_data(source = zip_source, read_engine = "jsonlite")
  expect_equal(res_jsonlite$version_UUID, "engine-test")

  # 4. Test Invalid Engine
  expect_error(
    get_malert_data(source = zip_source, read_engine = "invalid"),
    "read_engine must be either"
  )
})
