# testing that the get_senscape_data function returns the expected number of records.
test_that("get_senscape_data works", {
  expect_equal(nrow(get_senscape_data(key_path = "auth/senscape_api_key.txt", start_datetime = lubridate::as_datetime("2023-03-07"), end_datetime = lubridate::as_datetime("2023-03-08"))), 192)
})
