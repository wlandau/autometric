test_that("log_start()", {
  skip_if_not(log_support())
  temp <- tempfile()
  on.exit(unlink(temp))
  log_start(seconds = 0.5, pids = c(local = Sys.getpid()),  path = temp)
  log_start(seconds = 0.5, pids = Sys.getpid(), path = temp) # idempotent
  Sys.sleep(2)
  log_stop()
  Sys.sleep(2)
  out <- readLines(temp)
  expect_gt(length(out), 1L)
  expect_true(all(nzchar(out)))
})

test_that("log_start() mock no support", {
  old_option <- getOption("autometric_mock_no_support")
  on.exit(options(autometric_mock_no_support = old_option))
  options(autometric_mock_no_support = TRUE)
  expect_error(log_start(error = TRUE))
})
