test_that("returns correct values", {
  expect_equal(decimal_places(40), 0)
  expect_equal(decimal_places(40.1), 1)
  expect_equal(decimal_places(40.56), 2)
  expect_equal(decimal_places(40.565), 3)
})
