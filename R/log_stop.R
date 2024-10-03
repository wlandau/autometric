#' @title Stop the log thread.
#' @export
#' @description Stop the background thread that periodically writes
#'   system usage metrics of the current R process to a log file.
#' @details The background thread is detached, so is there no way to
#'   directly terminate it (other than terminating the main thread,
#'   i.e. restarting R). [log_stop()] merely signals to the thread
#'   using a static C variable protected by a mutex. It may take
#'   time for the thread to notice, depending on the value of `seconds`
#'   you supplied to [log_start()]. For this reason, you may see one or two
#'   lines in the log even after you call [log_stop()].
#' @return `NULL` (invisibly). Called for its side effects.
#' @examples
#'   path <- tempfile()
#'   log_start(seconds = 0.5, path = path)
#'   Sys.sleep(2)
#'   log_stop()
#'   log_read(path)
#'   unlink(path)
log_stop <- function() {
  .Call(r_log_stop, PACKAGE = "autometric")
  invisible()
}
