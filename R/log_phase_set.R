#' @title Set log phase
#' @export
#' @description Set the current log phase.
#' @return `NULL` (invisibly). Called for its side effects.
#' @param phase Character string with the phase of the log.
#'   Only the first 255 characters are used.
#'   Cannot include the pipe character `"|"`
#'   because it is the delimiter of fields in the log output.
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
log_phase_set <- function(phase) {
  stopifnot(is.character(phase))
  stopifnot(length(phase) == 1L)
  stopifnot(!anyNA(phase))
  stopifnot(!any(grepl("|", phase, fixed = TRUE)))
  .Call(r_log_phase_set, phase, PACKAGE = "autometric")
  invisible()
}
