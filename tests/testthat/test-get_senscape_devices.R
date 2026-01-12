test_that("bind_senscape_devices handles heterogeneous device records", {
  rec3 = list(`_id` = "c3", name = "bar", tags = NULL)
  rec3[[NA_character_]] = "blank"

  devices = list(
    list(`_id` = "a1", name = "foo"),
    list(`_id` = "b2", tags = c("x", "y"), extra = 5),
    rec3
  )

  res = mosquitoR:::bind_senscape_devices(devices)

  expect_equal(nrow(res), 3)
  expect_true("_id" %in% names(res))
  expect_true(all(nzchar(names(res))))
  expect_equal(res$`_id`, c("a1", "b2", "c3"))
})
