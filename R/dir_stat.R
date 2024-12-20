#' @title Efficiently describe files in a directory.
#' @export
#' @family utilities
#' @description List the paths, sizes, modification times,
#'   of all the regular files at (or linked from)
#'   the top level in a directory.
#' @details In large computational pipelines, it is common to end up with
#'   tens of thousands of log files in a directory.
#'   At this level of scale, [base::file.info()]
#'   is slow on older file systems.
#'   [autometric::dir_stat()] can be up to 40 times faster where
#'   the C implementation is supported
#'   (POSIX.1-2008 machines and Mac OS).
#'
#'   [dir_stat()] is not recursive: it only queries regular files at the
#'   top level of a directory. In addition, it follows symbolic links:
#'   if a file is a link, then [dir_stat()] describes the file it points
#'   to, rather than the link itself.
#' @return A data frame with one row per file and columns for the file path,
#'   numeric size, and modification time stamp of each file.
#'   The units of these last two columns are controlled by the
#'   `units_size` and `units_mtime` arguments, respectively.
#' @param path Character string, file path to the directory of files
#'   to describe.
#' @param units_size Character string with the units of the returned
#'   `size` column in the output: `"megabytes"`, `"bytes"`, `"kilobytes"`,
#'   or `"gigabytes"`.
#' @param units_mtime Character string with the units of the returned
#'   `mtime` column in the output with file modification time stamps.
#'   Choices are `"POSIXct` for a `POSIXct` time object or `"numeric"`
#'   for an ordinary numeric vector.
#' @param recent Either `NULL` or an optional `"difftime"` object.
#'   If a `"difftime"` object is supplied, then [dir_stat()]
#'   only shows the most recently modified files in that time window.
#'   For example, `recent = as.difftime(1.5, units = "hours")` tells
#'   [dir_stat()] to only return information on files modified within
#'   the last 1.5 hours.
#' @param method Character string, type of implementation used.
#'   Set to `"c"` for an implementation that is up to 40 times faster than
#'   [base::file.info()] but may not be supported on certain platforms.
#'   Set to `"r"` to run [base::file.info()], which is slower.
#'   If `method` is `"c"` but the C implementation is not supported
#'   on your platform, [dir_stat()] automatically falls back on
#'   [base::file.info()].
#'   The C implementation is supported on POSIX.1-2008 machines and on Mac OS.
#' @examples
#'   file.create(tempfile())
#'   file.create(tempfile())
#'   dir_stat(tempdir(), recent = as.difftime(1, units = "secs"))
dir_stat <- function(
  path,
  units_size = c("megabytes", "bytes", "kilobytes", "gigabytes"),
  units_mtime = c("POSIXct", "numeric"),
  recent = NULL,
  method = c("c", "r")
) {
  stopifnot(is.character(path))
  stopifnot(!anyNA(path))
  stopifnot(all(nzchar(path)))
  stopifnot(dir.exists(path))
  units_size <- match.arg(units_size)
  units_mtime <- match.arg(units_mtime)
  method <- match.arg(method)
  if (method == "r" || is.null(out <- dir_stat_c(path, units_mtime))) {
    out <- dir_stat_r(path, units_mtime)
  }
  out$size <- out$size * get_factor_size(units_size)
  if (!is.null(recent)) {
    stopifnot(length(recent) == 1L)
    stopifnot(!anyNA(recent))
    stopifnot(inherits(recent, "difftime"))
    out <- out[.POSIXct(out$mtime) > Sys.time() - recent, ]
  }
  out
}

dir_stat_c <- function(path, units_mtime) {
  out <- .Call(r_dir_stat, path, PACKAGE = "autometric")
  if (identical(units_mtime, "POSIXct")) {
    out$mtime <- .POSIXct(out$mtime)
  }
  as.data.frame(out)
}

dir_stat_r <- function(path, units_mtime) {
  directories <- list.dirs(path, full.names = TRUE, recursive = FALSE)
  files <- setdiff(list.files(path, full.names = TRUE), directories)
  info <- file.info(files, extra_cols = FALSE)
  out <- data.frame(
    path = rownames(info),
    size = as.numeric(info$size),
    mtime = info$mtime
  )
  if (identical(units_mtime, "numeric")) {
    out$mtime <- as.numeric(out$mtime)
  }
  out
}
