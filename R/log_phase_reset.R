#' @title Reset log phase
#' @export
#' @family phase
#' @description Reset the current log phase to the default value.
#' @return `NULL` (invisibly). Called for its side effects.
#' @examples
#'   path <- tempfile()
#'   log_phase_get()
#'   log_print(path = path)
#'   log_phase_set("different")
#'   log_phase_get()
#'   log_print(path = path)
#'   log_phase_reset()
#'   log_phase_get()
#'   log_read(path)
log_phase_reset <- function() {
  .Call(r_log_phase_reset, PACKAGE = "autometric")
  invisible()
}
