test_that("rounding down to nearest 0.05 works", {
  expect_equal(round_down(4.569, 0.05), 4.55)
})

test_that("rounding down to nearest 0.025 works", {
  expect_equal(round_down(4.569, 0.025), 4.55)
  expect_equal(round_down(4.579, 0.025), 4.575)
})
