local({
  if (log_support()) {
    path <- tempfile()
    log_print(seconds = 0.5, path = path)
    out <- log_read(path)
    expect_equal(nrow(out), 1L)
    expect_equal(
      colnames(out),
      c(
        "version", "pid", "name", "status", "time",
        "core", "cpu", "resident", "virtual"
      )
    )
    for (field in colnames(out)) {
      expect_equal(unique(out$status), 0L)
      expect_false(anyNA(out[[field]]))
    }
    unlink(path)
  }
})

local({
  if (log_support()) {
    dir1 <- tempfile()
    dir2 <- tempfile()
    dir3 <- file.path(dir2, "dir")
    file <- tempfile()
    dir.create(dir1)
    dir.create(dir2)
    dir.create(dir3)
    log_print(seconds = 0.5, path = file.path(dir1, "x"))
    file.copy(file.path(dir1, "x"), file.path(dir1, "y"))
    file.copy(file.path(dir1, "x"), file.path(dir2, "y"))
    file.copy(file.path(dir1, "x"), file.path(dir3, "z"))
    file.copy(file.path(dir1, "x"), file)
    out <- log_read(c(dir1, file, dir2, tempfile()))
    expect_equal(nrow(out), 5L)
    expect_equal(
      colnames(out),
      c(
        "version", "pid", "name", "status", "time",
        "core", "cpu", "resident", "virtual"
      )
    )
    for (field in colnames(out)) {
      expect_equal(unique(out$status), 0L)
      expect_false(anyNA(out[[field]]))
    }
    unlink(c(dir1, dir2, dir3, file), recursive = TRUE)
  }
})

local({
  package <- getNamespace("autometric")
  expect_equal(package$get_factor_cpu("percentage"), 1)
  expect_equal(package$get_factor_cpu("fraction"), 1 / 100)
})

local({
  package <- getNamespace("autometric")
  expect_equal(package$get_factor_time("seconds"), 1)
  expect_equal(package$get_factor_time("minutes"), 1 / 60)
  expect_equal(package$get_factor_time("hours"), 1 / (60 * 60))
  expect_equal(package$get_factor_time("days"), 1 / (60 * 60 * 24))
})

local({
  package <- getNamespace("autometric")
  expect_equal(package$get_factor_memory("bytes"), 1)
  expect_equal(package$get_factor_memory("kilobytes"), 1e-3)
  expect_equal(package$get_factor_memory("megabytes"), 1e-6)
  expect_equal(package$get_factor_memory("gigabytes"), 1e-9)
})
