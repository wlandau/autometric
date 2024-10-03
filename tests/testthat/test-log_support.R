test_that("log_support()", {
  out <- log_support()
  expect_true(isTRUE(out) || isFALSE(out))
})

test_that("log_support() mocking", {
  old_option <- getOption("autometric_mock_no_support")
  on.exit(options(autometric_mock_no_support = old_option))
  options(autometric_mock_no_support = TRUE)
  expect_false(log_support())
})
