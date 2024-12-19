#' @title Efficiently describe files in a directory.
#' @export
#' @family utilities
#' @description List the paths, sizes, modification times,
#'   of all the regular files at the top level in a directory.
#' @details In large computational pipelines, it is common to end up with
#'   tens of thousands of log files in a directory.
#'   At this level of scale, [base::file.info()]
#'   is slow on older file systems.
#'   [autometric::dir_stat()] can be up to 40 times faster.
#'
#'   [dir_stat()] is not recursive: it only queries regular files at the
#'   top level of a directory. In addition, it follows symbolic links:
#'   if a file is a link, then [dir_stat()] describes the file it points
#'   to, rather than the link itself.
#' @return A data frame with one row per file and columns for the file path,
#'   size in bytes, and modification time stamp of each file.
#' @param path Character string, file path to the directory of files
#'   to describe.
#' @examples
#'   file.create(tempfile())
#'   file.create(tempfile())
#'   dir_stat(tempdir())
dir_stat <- function(path) {
  stopifnot(is.character(path))
  stopifnot(!anyNA(path))
  stopifnot(all(nzchar(path)))
  stopifnot(dir.exists(path))
  out <- .Call(r_dir_stat, path, PACKAGE = "autometric")
  if (is.null(out)) {
    out <- file.info(list.files(out, full.names = TRUE), extra_cols = FALSE)
  }
  as.data.frame(out)
}
