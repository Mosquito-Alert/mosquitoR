context("get_malert_data caching and file sources")

test_that("get_malert_data works with source as a file path", {
  # Create a minimal mock ZIP file in a temporary directory
  temp_dir <- withr::local_tempdir(pattern = "malert_test_")

  json_dir <- file.path(temp_dir, "home/webuser/webapps/tigaserver/static")
  dir.create(json_dir, recursive = TRUE)

  # Create one JSON file for the current year
  curr_year <- lubridate::year(lubridate::today())
  json_file <- file.path(json_dir, paste0("all_reports", curr_year, ".json"))
  jsonlite::write_json(
    list(list(version_UUID = "test-1", creation_year = curr_year)),
    json_file,
    auto_unbox = TRUE
  )

  zip_file <- file.path(temp_dir, "test_reports.zip")

  # Create zip file safely changing directory
  withr::with_dir(temp_dir, {
    utils::zip(zip_file, files = "home", flags = "-r9Xq")
  })

  # Call get_malert_data with the zip file path as source
  result <- get_malert_data(source = zip_file)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$version_UUID, "test-1")
})

test_that("get_malert_data uses cache_path and reuses it", {
  temp_dir <- withr::local_tempdir(pattern = "malert_cache_test_")

  # Mock ZIP
  json_dir <- file.path(temp_dir, "home/webuser/webapps/tigaserver/static")
  dir.create(json_dir, recursive = TRUE)
  curr_year <- lubridate::year(lubridate::today())
  jsonlite::write_json(
    list(list(version_UUID = "cached-1", creation_year = curr_year)),
    file.path(json_dir, paste0("all_reports", curr_year, ".json")),
    auto_unbox = TRUE
  )

  zip_fixture <- file.path(temp_dir, "fixture.zip")

  withr::with_dir(temp_dir, {
    utils::zip(zip_fixture, files = "home", flags = "-r9Xq")
  })

  cache_file <- file.path(temp_dir, "my_cache.zip")

  # Mock download_malert_zip to copy our fixture
  local_mocked_bindings(
    download_malert_zip = function(source, doi, destfile) {
      file.copy(zip_fixture, destfile)
      return(destfile)
    }
  )

  # 1. First call: Should download (call our mock) and save to cache_path
  expect_false(file.exists(cache_file))
  result1 <- get_malert_data(source = "github", cache_path = cache_file)
  expect_true(file.exists(cache_file))
  expect_equal(result1$version_UUID, "cached-1")

  # 2. Modify the cached file to prove it's being used
  jsonlite::write_json(
    list(list(version_UUID = "reused-cache", creation_year = curr_year)),
    file.path(json_dir, paste0("all_reports", curr_year, ".json")),
    auto_unbox = TRUE
  )

  withr::with_dir(temp_dir, {
    utils::zip(cache_file, files = "home", flags = "-r9Xq")
  })

  # 3. Second call: Should use the existing cache_file without calling download_malert_zip
  # If it calls download_malert_zip, it will overwrite with "cached-1" data
  expect_message(
    result2 <- get_malert_data(source = "github", cache_path = cache_file),
    "Using cached file"
  )
  expect_equal(result2$version_UUID, "reused-cache")
})
