#' @title Start the log thread.
#' @export
#' @description Start a background thread that periodically writes
#'   system usage metrics of the current R process to a log file.
#'   See [log_read()] for explanations of the specific metrics.
#' @details Only one thread can run at a time. If the thread is already
#'   running, then [log_start()] does not start an additional one.
#'   Before creating a new thread, call [log_stop()] to terminate
#'   the first one.
#' @return `NULL` (invisibly). Called for its side effects.
#' @inheritParams log_print
#' @param seconds Positive number, number of seconds between writes to the
#'   log file. This number should be noticeably large, anywhere between
#'   half a second to several seconds or minutes.
#'   A low number of seconds could burden the operating system
#'   and generate large log files. Because of the way CPU usage measurements
#'   work, the first log entry starts only after after the first interval of
#'   `seconds` has passed.
#' @examples
#'   path <- tempfile()
#'   log_start(seconds = 0.5, path = path)
#'   Sys.sleep(2)
#'   log_stop()
#'   Sys.sleep(2)
#'   log_read(path)
#'   unlink(path)
log_start <- function(
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
  stopifnot(is.numeric(pids))
  stopifnot(all(is.finite(pids)))
  stopifnot(all(pids >= 0L))
  stopifnot(all(length(pids) > 0L))
  stopifnot(is.numeric(seconds))
  stopifnot(!anyNA(seconds))
  stopifnot(seconds > 0)
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
  pids <- as.integer(pids)
  .Call(
    r_log_start,
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
