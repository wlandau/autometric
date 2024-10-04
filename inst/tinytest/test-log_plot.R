local({
  if (Sys.getenv("NOT_CRAN") == "true" && log_support()) {
    temp <- tempfile()
    grDevices::png(temp)
    pid <- Sys.getpid()
    for (index in seq_len(2L)) {
      log_print(seconds = 0.5, pids = c(local = pid), path = temp)
    }
    log <- log_read(temp)
    log_plot(log, pid = NULL, name = NULL)
    log_plot(log, pid = pid, name = NULL)
    log_plot(log, pid = NULL, name = "local")
    tinytest::expect_error(log_plot(log, pid = pid, name = "local"))
    tinytest::expect_true(TRUE)
    dev.off()
    unlink(temp, recursive = TRUE)
  }
})
