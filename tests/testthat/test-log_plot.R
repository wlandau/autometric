test_that("log_plot()", {
  skip_on_cran()
  skip_if_not(log_support())
  temp <- tempfile()
  on.exit(unlink(temp, recursive = TRUE))
  grDevices::png(temp)
  on.exit(dev.off(), add = TRUE)
  pid <- Sys.getpid()
  for (index in seq_len(2L)) {
    log_print(seconds = 0.5, pids = c(local = pid), path = temp)
  }
  log <- log_read(temp)
  log_plot(log, pid = NULL, name = NULL)
  log_plot(log, pid = pid, name = NULL)
  log_plot(log, pid = NULL, name = "local")
  expect_error(log_plot(log, pid = pid, name = "local"))
  expect_true(TRUE)
})
