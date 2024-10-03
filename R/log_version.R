#' @title Check the package version in the C code.
#' @export
#' @keywords internal
#' @description Not for users.
#' @return Character string with the package version.
#' @examples
#'   log_version()
log_version <- function() {
  .Call(r_log_version, PACKAGE = "autometric")
}
