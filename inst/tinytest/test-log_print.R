local({
  if (log_support()) {
    temp <- tempfile()
    log_print(path = temp, pids = Sys.getpid())
    log_print(path = temp, pids = c(local = Sys.getpid()))
    out <- readLines(temp)
    tinytest::expect_equal(length(out), 2L)
    tinytest::expect_true(all(nzchar(out)))
    unlink(temp)
  }
})

local({
  old_option <- getOption("autometric_mock_no_support")
  options(autometric_mock_no_support = TRUE)
  tinytest::expect_error(log_print(error = TRUE))
  options(autometric_mock_no_support = old_option)
})

