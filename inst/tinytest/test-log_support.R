local({
  out <- log_support()
  expect_true(isTRUE(out) || isFALSE(out))
})

local({
  old_option <- getOption("autometric_mock_no_support")
  options(autometric_mock_no_support = TRUE)
  expect_false(log_support())
  options(autometric_mock_no_support = old_option)
})
