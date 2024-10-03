#' @useDynLib autometric, .registration = TRUE
#' @importFrom graphics lines
#' @importFrom utils globalVariables read.table
NULL

globalVariables(
  names = c(
    "r_log_active",
    "r_log_print",
    "r_log_stop",
    "r_log_support"
  ),
  package = "autometric"
)
