#' @title Plot a metric of a process over time
#' @export
#' @description Visualize a metric of a log over time for a single process ID
#'   in a single log file.
#' @return A base plot of a metric of a log over time.
#' @param log Data frame returned by [log_read()]. Must be nonempty.
#'   [log_plot()] only includes rows with status code equal to 0.
#' @param metric Character string with the name of a metric to plot
#'   against time. Must be only a single string.
#'   Defaults to the resident set size (RSS), the total amount of memory
#'   used by the process.
#'   See [log_read()] for descriptions of the metrics available.
#' @param pid Either `NULL` or a non-negative integer with the process
#'   ID to plot. At least one of `pid` or `name` must be `NULL`.
#' @param name Either `NULL` or a non-negative integer with the name of
#'   the process to plot. The name was previously specified in the
#'   names of the `pid` argument of [log_start()] or [log_print()].
#'   At least one of `pid` or `name` must be `NULL`.
#' @param phase Either `NULL` or a character string specifying the
#'   name of a log phase (see [log_phase_set()]).
#'   If not `NULL`, then [log_print()] will only visualize data from
#'   the given log phase.
#' @param ... Named optional parameters to pass to the base
#'   function `plot()`.
#' @examples
#'   path <- tempfile()
#'   log_start(seconds = 0.25, path = path)
#'   Sys.sleep(1)
#'   log_stop()
#'   Sys.sleep(2)
#'   log <- log_read(path)
#'   log_plot(log, metric = "cpu")
#'   unlink(path)
log_plot <- function(
  log,
  pid = NULL,
  name = NULL,
  phase = NULL,
  metric = "resident",
  ...
) {
  stopifnot(is.data.frame(log))
  stopifnot(nrow(log) > 0L)
  stopifnot(is.character(metric))
  stopifnot(length(metric) == 1L)
  stopifnot(nzchar(metric))
  stopifnot(all(c("time", metric) %in% colnames(log)))
  log <- log[as.integer(log$status) == 0L,, drop = FALSE] # nolint
  if (!is.null(phase) && "phase" %in% colnames(log)) {
    stopifnot(is.character(phase))
    stopifnot(length(phase) == 1L)
    stopifnot(!anyNA(phase))
    log <- log[log$phase == phase,, drop = FALSE] # nolint
  }
  if (is.null(pid) && is.null(name)) {
    stopifnot("pid" %in% colnames(log))
    pid <- log$pid[1L]
  }
  if (!is.null(pid) && !is.null(name)) {
    stop("At least one of pid or name must be NULL.")
  }
  if (!is.null(pid)) {
    stopifnot(is.numeric(pid))
    stopifnot(length(pid) == 1L)
    stopifnot(all(is.finite(pid)))
    stopifnot("pid" %in% colnames(log))
    log <- log[as.integer(log$pid) == as.integer(pid),, drop = FALSE] # nolint
    default_title <- paste("process ID:", pid)
  }
  if (!is.null(name)) {
    stopifnot(is.character(name))
    stopifnot(length(name) == 1L)
    stopifnot(!anyNA(name))
    stopifnot("name" %in% colnames(log))
    log <- log[as.character(log$name) == name,, drop = FALSE] # nolint
    default_title <- paste("process name:", name)
  }
  if (!is.null(phase)) {
    default_title <- paste0("log phase: ", phase, "\n", default_title)
  }
  args <- list(
    x = log$time,
    y = log[[metric]],
    xlab = "time",
    ylab = metric,
    ...
  )
  if (is.null(args$main)) {
    args$main <- default_title
  }
  if (is.null(args$ylim)) {
    args$ylim <- c(min(c(0, log[[metric]])), max(log[[metric]]))
  }
  do.call(what = plot, args = args)
  graphics::lines(x = log$time, y = log[[metric]])
}
