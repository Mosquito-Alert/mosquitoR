
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
  # Mock check_mirai_installed to return FALSE
  local_mocked_bindings(
    check_mirai_installed = function() FALSE
  )
  
  # "auto" should fallback to FALSE
  expect_false(should_use_parallel("auto"))
  
  # TRUE should error
  expect_error(should_use_parallel(TRUE), "package is not installed")
})

test_that("should_use_parallel handles no active daemons", {
  # Mock check_mirai_installed and check_mirai_daemons
  local_mocked_bindings(
    check_mirai_installed = function() TRUE,
    check_mirai_daemons = function() 0
  )
  
  # "auto" should fallback to FALSE
  expect_false(should_use_parallel("auto"))
  
  # TRUE should error
  expect_error(should_use_parallel(TRUE), "no 'mirai' daemons are active")
})

test_that("should_use_parallel enables parallel when ready", {
  # Mock check_mirai_installed and check_mirai_daemons
  local_mocked_bindings(
    check_mirai_installed = function() TRUE,
    check_mirai_daemons = function() 2
  )
  
  # "auto" should return TRUE
  expect_true(should_use_parallel("auto"))
  
  # TRUE should return TRUE
  expect_true(should_use_parallel(TRUE))
})
