#' @title Check the log thread.
#' @export
#' @family log
#' @description Check if the log is running.
#' @return `TRUE` if a background thread is actively writing to the log,
#'   `FALSE` otherwise. The result is based on a static C variable,
#'   so the information is second-hand.
#' @examples
#'   path <- tempfile()
#'   log_active()
#'   log_start(seconds = 0.5, path = path)
#'   log_active()
#'   Sys.sleep(2)
#'   log_stop()
#'   Sys.sleep(2)
#'   log_active()
#'   unlink(path)
log_active <- function() {
  .Call(r_log_active, PACKAGE = "autometric")
}
