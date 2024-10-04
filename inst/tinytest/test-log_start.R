local({
  if (log_support()) {
    temp <- tempfile()
    log_start(seconds = 0.5, pids = c(local = Sys.getpid()),  path = temp)
    log_start(seconds = 0.5, pids = Sys.getpid(), path = temp) # idempotent
    Sys.sleep(2)
    log_stop()
    Sys.sleep(2)
    out <- readLines(temp)
    expect_true(length(out) > 1L)
    expect_true(all(nzchar(out)))
    unlink(temp)
  }
})

local({
  old_option <- getOption("autometric_mock_no_support")
  options(autometric_mock_no_support = TRUE)
  expect_error(log_start(error = TRUE))
  options(autometric_mock_no_support = old_option)
})
