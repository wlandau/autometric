#' @title Print once to the log.
#' @export
#' @family log
#' @description Sample CPU load metrics and
#'   print a single line to the log for each process in `pids`.
#'   Used for debugging and testing only. Not for users.
#' @return `NULL` (invisibly). Called for its side effects.
#' @param path Character string, path to a file to log resource usage.
#'   On Windows, the path must point to a physical file on disk.
#'   On Unix-like systems, `path` can be `"/dev/stdout"` to print to
#'   standard output or `"/dev/stderr"` to print to standard error.
#'
#'   Standard output is the most convenient option for high-performance
#'   computing scenarios where worker processes already write to log files.
#'   Such workers usually already redirect standard output to a
#'   physical file, as with a cluster like SLURM,
#'   or capture messages with
#'   [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/).
#'
#'   Normally, standard output and standard error are discouraged because
#'   of how they interact with the R API and R console. However, the
#'   exported user interface of `autometric` only ever
#'   prints from a detached POSIX thread where it is unsafe to
#'   use `Rprintf()` or `REprintf()`.
#' @param seconds Positive number, number of seconds to sample CPU load
#'   metrics before printing to the log.
#'   This number should be at least 1, usually more.
#'   A low number of seconds could burden the operating system
#'   and generate large log files.
#' @param pids Nonempty vector of non-negative integers
#'   of process IDs to monitor. NOTE: On Mac OS, only the currently running
#'   process can be monitored.
#'   This is due to security restrictions around certain system calls, c.f.
#'   <https://os-tres.net/blog/2010/02/17/mac-os-x-and-task-for-pid-mach-call/>. # nolint
#'   If the `pids` vector is named, then the names will show alongside the
#'   process IDs in the log entries. Names cannot include the pipe character
#'   `"|"` because it is the delimiter of fields in the log output.
#' @param error `TRUE` to throw an error if the thread is not supported on
#'   the current platform. (See [log_support()].)
#' @examples
#'   path = tempfile()
#'   log_print(path = path)
#'   log_read(path)
#'   unlink(path)
log_print <- function(
  path,
  seconds = 1,
  pids = c(local = Sys.getpid()),
  error = getOption("autometric_error", TRUE)
) {
  stopifnot(isTRUE(error) || isFALSE(error))
  if (!log_support() && error) {
    stop(
      "Cannot log metrics because this system has insufficient support.",
      call. = FALSE
    )
  }
  stopifnot(is.numeric(seconds))
  stopifnot(!anyNA(seconds))
  stopifnot(seconds > 0)
  stopifnot(is.numeric(pids))
  stopifnot(all(is.finite(pids)))
  stopifnot(all(pids >= 0L))
  stopifnot(all(length(pids) > 0L))
  stopifnot(is.character(path))
  stopifnot(length(path) == 1L)
  stopifnot(!anyNA(path))
  stopifnot(nzchar(path))
  path <- as.character(path)
  if (!file.exists(path)) {
    dir <- dirname(path)
    if (!file.exists(dir)) {
      dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    }
    file.create(path, showWarnings = FALSE)
  }
  if (!file.exists(path)) {
    stop("unable to create log file ", path) # nocov
  }
  nanoseconds <- as.integer(1e9L * (seconds - floor(seconds)))
  seconds <- as.integer(floor(seconds))
  n_pids <- length(pids)
  if (is.null(names(pids))) {
    names <- rep("", n_pids)
  } else {
    names <- names(pids)
  }
  stopifnot(!any(grepl("|", names, fixed = TRUE)))
  pids <- as.integer(pids)
  .Call(
    r_log_print,
    path,
    seconds,
    nanoseconds,
    pids,
    names,
    n_pids,
    PACKAGE = "autometric"
  )
  invisible()
}
