local({
  if (log_support()) {
    temp <- tempfile()
    path <- file.path(temp, "x", "y", "z")
    log_print(path = path, pids = Sys.getpid())
    log_print(path = path, pids = c(local = Sys.getpid()))
    out <- readLines(path)
    expect_equal(length(out), 2L)
    expect_true(all(nzchar(out)))
    unlink(temp, recursive = TRUE, force = TRUE)
  }
})

local({
  old_option <- getOption("autometric_mock_no_support")
  options(autometric_mock_no_support = TRUE)
  expect_error(log_print(error = TRUE))
  options(autometric_mock_no_support = old_option)
})
