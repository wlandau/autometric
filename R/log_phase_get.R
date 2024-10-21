#' @title Get log phase
#' @export
#' @description Get the current log phase.
#' @return Character string with the name of the current log phase.
#' @examples
#'   log_phase_get()
#'   log_phase_set("different")
#'   log_phase_get()
#'   log_phase_reset()
#'   log_phase_get()
log_phase_get <- function() {
  .Call(r_log_phase_get, PACKAGE = "autometric")
}
