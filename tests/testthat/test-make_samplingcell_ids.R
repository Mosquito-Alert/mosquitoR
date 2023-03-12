test_that("Correct number of IDs are producted", {
  expect_equal(length(make_samplingcell_ids(lon=c(2.1686, 2.1032), lat=c(41.3874, 41.2098), 0.05)), 2)
})
