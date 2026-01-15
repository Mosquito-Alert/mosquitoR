
# Tests for parallel processing helper
# This file tests the logic for determining whether to run in parallel
# based on user arguments and system state (mirai availability/daemons).

test_that("should_use_parallel validation", {
  expect_error(should_use_parallel(123), "must be 'auto', TRUE, or FALSE")
  expect_error(should_use_parallel("parallel"), "must be 'auto'")
})

test_that("should_use_parallel handles explicit FALSE", {
  expect_false(should_use_parallel(FALSE))
})

test_that("should_use_parallel handles missing mirai package", {
  # Mock requireNamespace to return FALSE
  m <- mockery::mock(FALSE, cycle = TRUE)
  mockery::stub(should_use_parallel, "requireNamespace", m)
  
  # "auto" should fallback to FALSE
  expect_false(should_use_parallel("auto"))
  
  # TRUE should error
  expect_error(should_use_parallel(TRUE), "package is not installed")
})

test_that("should_use_parallel handles no active daemons", {
  # Mock requireNamespace to return TRUE
  m_req <- mockery::mock(TRUE, cycle = TRUE)
  
  # Mock check_mirai_daemons to return 0
  m_daemons <- mockery::mock(0, cycle = TRUE)
  
  mockery::stub(should_use_parallel, "requireNamespace", m_req)
  mockery::stub(should_use_parallel, "check_mirai_daemons", m_daemons)
  
  # "auto" should fallback to FALSE
  expect_false(should_use_parallel("auto"))
  
  # TRUE should error
  expect_error(should_use_parallel(TRUE), "no 'mirai' daemons are active")
})

test_that("should_use_parallel enables parallel when ready", {
  # Mock requireNamespace to return TRUE
  m_req <- mockery::mock(TRUE, cycle = TRUE)
  
  # Mock check_mirai_daemons to return 2
  m_daemons <- mockery::mock(2, cycle = TRUE)
  
  mockery::stub(should_use_parallel, "requireNamespace", m_req)
  mockery::stub(should_use_parallel, "check_mirai_daemons", m_daemons)
  
  # "auto" should return TRUE
  expect_true(should_use_parallel("auto"))
  
  # TRUE should return TRUE
  expect_true(should_use_parallel(TRUE))
})
