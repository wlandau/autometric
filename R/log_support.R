#' @title Log support
#' @export
#' @description Check if your system supports background logging.
#' @details The background logging functionality requires a Linux, Mac,
#'   or Windows computer, It also requires POSIX thread support
#'   and the `nanosleep()` C function.
#' @return `TRUE` if your system supports background logging, `FALSE`
#'   otherwise.
#' @examples
#'   log_support()
log_support <- function() {
  if (getOption("autometric_mock_no_support", FALSE)) {
    FALSE
  } else {
    .Call(r_log_support, PACKAGE = "autometric")
  }
}
