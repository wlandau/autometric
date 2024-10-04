local({
  if (log_support()) {
    path <- tempfile()
    expect_false(log_active())
    log_start(seconds = 0.5, path = path)
    expect_true(log_active())
    log_stop()
    Sys.sleep(2)
    expect_false(log_active())
    unlink(path)
  }
})
