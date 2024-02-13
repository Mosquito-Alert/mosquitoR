# testing that the get_senscape_data function returns the expected number of records.
test_that("get_senscape_data works", {
  expect_equal(nrow(get_senscape_data(api_key = SENSCAPE_API_KEY, start_datetime = lubridate::as_datetime("2023-03-07"), end_datetime = lubridate::as_datetime("2023-03-08"), deviceIds = c("5f1076c998fda900151ff683", "5f1076c998fda900151ff683", "5f10762e98fda900151ff680", "5f10767c98fda900151ff681", "5f1076ae98fda900151ff682"))), 191)
})
