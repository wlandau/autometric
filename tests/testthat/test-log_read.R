test_that("log_read() one file", {
  skip_if_not(log_support())
  path <- tempfile()
  on.exit(unlink(path))
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
})

test_that("log_read() many files", {
  skip_if_not(log_support())
  dir1 <- tempfile()
  dir2 <- tempfile()
  dir3 <- file.path(dir2, "dir")
  file <- tempfile()
  on.exit(unlink(c(dir1, dir2, dir3, file), recursive = TRUE))
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
})

test_that("get_factor_cpu()", {
  expect_equal(get_factor_cpu("percentage"), 1)
  expect_equal(get_factor_cpu("fraction"), 1 / 100)
})

test_that("get_factor_time()", {
  expect_equal(get_factor_time("seconds"), 1)
  expect_equal(get_factor_time("minutes"), 1 / 60)
  expect_equal(get_factor_time("hours"), 1 / (60 * 60))
  expect_equal(get_factor_time("days"), 1 / (60 * 60 * 24))
})

test_that("get_factor_memory()", {
  expect_equal(get_factor_memory("bytes"), 1)
  expect_equal(get_factor_memory("kilobytes"), 1e-3)
  expect_equal(get_factor_memory("megabytes"), 1e-6)
  expect_equal(get_factor_memory("gigabytes"), 1e-9)
})
