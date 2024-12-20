local({
  if (tolower(Sys.info()["sysname"]) != "windows") {
    for (units_mtime in c("POSIXct", "numeric")) {
      path <- tempfile()
      dir.create(path)
      writeLines("line", file.path(path, "a"))
      writeLines("line2", file.path(path, "b"))
      dir.create(file.path(path, "dir"))
      file.create(file.path(path, "dir", "x"))
      out_c <- dir_stat(
        path,
        method = "c",
        units_size = "bytes",
        units_mtime = units_mtime
      )
      out_r <- dir_stat(
        path,
        method = "r",
        units_size = "bytes",
        units_mtime = units_mtime
      )
      out_c$path <- basename(out_c$path)
      out_r$path <- basename(out_r$path)
      out_c$size <- as.integer(out_c$size)
      out_r$size <- as.integer(out_r$size)
      expect_equal(out_c, out_r)
      expect_equal(as.numeric(out_c$mtime) - as.numeric(out_r$mtime), c(0, 0))
      expect_equal(
        as.character(.POSIXct(out_c$mtime)),
        as.character(.POSIXct(out_r$mtime))
      )
      expect_equal(out_c$size[out_c$path == "a"], 5L)
      expect_equal(out_c$size[out_c$path == "b"], 6L)
      expect_equal(sort(colnames(out_c)), sort(c("path", "size", "mtime")))
      expect_equal(nrow(out_c), 2L)
      unlink(path, recursive = TRUE)
    }
  }
})

local({
  if (tolower(Sys.info()["sysname"]) != "windows") {
    path <- tempfile()
    dir.create(path)
    writeLines("line", file.path(path, "a"))
    writeLines("line2", file.path(path, "b"))
    out <- dir_stat(
      path,
      method = "c",
      units_size = "bytes",
      units_mtime = "numeric",
      recent = as.difftime(1, units = "hours")
    )
    out$path <- basename(out$path)
    expect_equal(nrow(out), 2L)
    expect_equal(out$size[out$path == "a"], 5L)
    expect_equal(out$size[out$path == "b"], 6L)
    expect_true(is.numeric(out$mtime))
    unlink(path, recursive = TRUE)
  }
})

local({
  if (tolower(Sys.info()["sysname"]) != "windows") {
    path <- tempfile()
    dir.create(path)
    out <- dir_stat(
      path,
      method = "c",
      units_size = "bytes",
      units_mtime = "numeric",
      recent = as.difftime(1, units = "hours")
    )
    expect_equal(nrow(out), 0L)
    expect_equal(sort(colnames(out)), sort(c("path", "size", "mtime")))
    unlink(path, recursive = TRUE)
  }
})

local({
  if (tolower(Sys.info()["sysname"]) != "windows") {
    path <- tempfile()
    dir.create(path)
    link <- file.path(path, "link")
    target <- tempfile()
    writeLines("a", target)
    file.symlink(from = target, to = link)
    out_c <- dir_stat(
      path,
      method = "c",
      units_size = "bytes",
      units_mtime = "numeric",
      recent = as.difftime(1, units = "hours")
    )
    out_r <- dir_stat(
      path,
      method = "r",
      units_size = "bytes",
      units_mtime = "numeric",
      recent = as.difftime(1, units = "hours")
    )
    expect_equal(out_c$size, 2L)
    expect_equal(out_r$size, 2L)
    writeLines("abc", target)
    out_c <- dir_stat(
      path,
      method = "c",
      units_size = "bytes",
      units_mtime = "numeric",
      recent = as.difftime(1, units = "hours")
    )
    out_r <- dir_stat(
      path,
      method = "r",
      units_size = "bytes",
      units_mtime = "numeric",
      recent = as.difftime(1, units = "hours")
    )
    expect_equal(out_c$size, 4L)
    expect_equal(out_r$size, 4L)
    unlink(c(path, target), recursive = TRUE)
  }
})

