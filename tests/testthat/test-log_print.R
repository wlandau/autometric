test_that("log_print() with names", {
  skip_if_not(log_support())
  temp <- tempfile()
  on.exit(unlink(temp))
  log_print(path = temp, pids = Sys.getpid())
  log_print(path = temp, pids = c(local = Sys.getpid()))
  out <- readLines(temp)
  expect_equal(length(out), 2L)
  expect_true(all(nzchar(out)))
})

test_that("log_print() mock no support", {
  old_option <- getOption("autometric_mock_no_support")
  on.exit(options(autometric_mock_no_support = old_option))
  options(autometric_mock_no_support = TRUE)
  expect_error(log_print(error = TRUE))
})
