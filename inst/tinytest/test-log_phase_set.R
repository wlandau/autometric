local({
  log_phase_reset()
  default <- log_phase_get()
  log_phase_set("different_phase")
  expect_equal(log_phase_get(), "different_phase")
  log_phase_reset()
  expect_equal(log_phase_get(), default)
})

local({
  if (log_support()) {
    default <- log_phase_get()
    path <- tempfile()
    log_print(seconds = 0.5, path = path)
    log_phase_set("different_phase")
    log_print(seconds = 0.5, path = path)
    log <- log_read(path)
    expect_true(any(default %in% log$phase))
    expect_true(any("different_phase" %in% log$phase))
    log_phase_reset()
    unlink(path)
  }
})

local({
  if (log_support()) {
    default <- log_phase_get()
    path <- tempfile()
    log_start(seconds = 0.5, path = path)
    Sys.sleep(2)
    log_phase_set("different_phase")
    Sys.sleep(2)
    log_stop()
    Sys.sleep(2)
    log <- log_read(path)
    expect_true(any(default %in% log$phase))
    expect_true(any("different_phase" %in% log$phase))
    log_phase_reset()
    unlink(path)
  }
})
