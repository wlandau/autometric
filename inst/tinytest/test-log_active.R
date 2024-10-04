local({
  if (log_support()) {
    path <- tempfile()
    tinytest::expect_false(log_active())
    log_start(seconds = 0.5, path = path)
    tinytest::expect_true(log_active())
    log_stop()
    Sys.sleep(2)
    tinytest::expect_false(log_active())
    unlink(path)
  }
})
