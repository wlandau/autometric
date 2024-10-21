#' @title Read a log.
#' @export
#' @description Read a log file into R.
#' @details [log_read()] is capable of reading a log file where both
#'   `autometric` and other processes have printed. Whenever `autometric`
#'   writes to a log, it bounds the beginning and end of the text
#'   with the keyword  `"__AUTOMETRIC__"`.
#'   that way, [log_read()] knows to only read and process the correct
#'   lines of the file.
#'
#'   In addition, it automatically converts the log data
#'   into the units  `units_time`,
#'   `units_cpu`, and `units_memory` arguments.
#' @return A data frame of metrics from the log with one row per log entry
#'   and columns with metadata and resource usage metrics.
#'   [log_read()] automatically converts the data into the units
#'   chosen with arguments `units_time`, `units_cpu`, and `units_memory`.
#'   The returned data frame has the following columns:
#'   * `version`: Version of the package used to write the log entry.
#'   * `pid`: Process ID monitored.
#'   * `status`: A status code for the log entry. Status 0 means
#'     logging succeeded. A status code not equal to 0 indicates
#'     something went wrong and the metrics should not be trusted.
#'   * `time`: numeric time stamp at which the entry was logged.
#'     [log_read()] automatically recenters this column so that time 0
#'     indicates the first logged entry.
#'     Use the `units_time` argument to customize the units of this field.
#'   * `core`: CPU load of the process scaled relative to a single
#'     CPU core. Measures the amount of time the process spends running
#'     during a given interval of elapsed time.
#'
#'     On Mac OS, the package uses native system calls to get CPU core usage.
#'     On Linux and Windows, the package calculates it manually using.
#'     user + kernel clock cycles that ran during a sampling interval.
#'     It measures the clock cycles that the process executed during
#'     the interval, converts the clock cycles into seconds,
#'     then divides the result by the elapsed time of the interval.
#'     The length of the sampling interval is the `seconds` argument
#'     supplied to [log_start()], or length of time between
#'     calls to [log_print()].
#'     The first `core` measurement is 0 to reflect that a full sampling
#'     interval has not elapsed yet.
#'
#'     `core` can be read in as a percentage or fraction, depending on
#'     the `units_cpu` argument.
#'   * `cpu`: `core` divided by the number of logical CPU cores.
#'     This metric measures the load on the machine as a whole,
#'     not just the CPU core it runs on.
#'     Use the `units_cpu` argument to customize the units of this field.
#'   * `rss`: resident set size, the total amount of memory used by the
#'     process at the time of logging. This include the memory unique
#'     to the process (unique set size USS) and shared memory.
#'     Use the `units_memory` argument to customize the units of this field.
#'   * `virtual`: total virtual memory available to the process.
#'     The process does not necessarily use all this memory, but
#'     it can request more virtual memory throughout its life cycle.
#'     Use the `units_memory` argument to customize the units of this field.
#' @param path Character vector of paths to files and/or directories
#'   of logs to read.
#' @param units_cpu Character string with the units of the `cpu` field.
#'   Defaults to `"percentage"` and must be in `c("percentage", "fraction")`.
#' @param units_memory Character string with the units of the
#'   `memory` field. Defaults to `"megabytes"` and must be in
#'   `c("megabytes", "bytes", "kilobytes", "gigabytes")`.
#' @param units_time Character string, units of the `time` field.
#'   Defaults to `"seconds"` and must be in
#'   `c("seconds", "minutes", "hours", "days")`.
#' @param hidden `TRUE` to include hidden files in the files and directories
#'   listed in `path`, `FALSE` to omit.
#' @examples
#'   path <- tempfile()
#'   log_start(seconds = 0.5, path = path)
#'   Sys.sleep(2)
#'   log_stop()
#'   Sys.sleep(2)
#'   log_read(path)
#'   unlink(path)
log_read <- function(
  path,
  units_cpu = c("percentage", "fraction"),
  units_memory = c("megabytes", "bytes", "kilobytes", "gigabytes"),
  units_time = c("seconds", "minutes", "hours", "days"),
  hidden = FALSE
) {
  stopifnot(is.character(path))
  stopifnot(!anyNA(path))
  stopifnot(all(nzchar(path)))
  units_cpu <- match.arg(units_cpu)
  units_memory <- match.arg(units_memory)
  units_time <- match.arg(units_time)
  out <- lapply(
    X = sort(unique(unlist(lapply(path, list_files, hidden = hidden)))),
    FUN = log_read_file,
    units_cpu = units_cpu,
    units_memory = units_memory,
    units_time = units_time
  )
  do.call(what = rbind, args = out)
}

log_read_file <- function(path, units_cpu, units_memory, units_time) {
  lines <- grep(pattern = "__AUTOMETRIC__", x = readLines(path), value = TRUE)
  lines <- gsub(".*__AUTOMETRIC__\\|(.*)\\|__AUTOMETRIC__.*", "\\1", lines)
  out <- utils::read.table(
    text = lines,
    sep = "|",
    header = FALSE,
    fill = TRUE
  )
  colnames(out) <- c(
    "version",
    "pid",
    "name",
    "status",
    "time",
    "core",
    "cpu",
    "resident",
    "virtual",
    "phase"
  )[seq_along(out)]
  order <- c(
    "version",
    "phase",
    "pid",
    "name",
    "status",
    "time",
    "core",
    "cpu",
    "resident",
    "virtual"
  )
  out <- out[, intersect(order, colnames(out))]
  out$version <- as.character(out$version)
  out$pid <- as.integer(out$pid)
  out$name <- as.character(out$name)
  out$name[is.na(out$name)] <- ""
  out$status <- as.integer(out$status)
  factor_cpu <- get_factor_cpu(units_cpu)
  factor_memory <- get_factor_memory(units_memory)
  factor_time <- get_factor_time(units_time)
  for (field in c("core", "cpu")) {
    out[[field]] <- as.numeric(out[[field]] * factor_cpu)
  }
  for (field in c("resident", "virtual")) {
    out[[field]] <- as.numeric(out[[field]] * factor_memory)
  }
  out$time <- as.numeric((out$time - min(out$time)) * factor_time)
  out
}

list_files <- function(path, hidden) {
  if (dir.exists(path)) {
    list.files(
      path = path,
      all.files = hidden,
      full.names = TRUE,
      recursive = TRUE,
      include.dirs = FALSE,
      no.. = TRUE
    )
  } else if (file.exists(path)) {
    path
  } else {
    character(0L)
  }
}

get_factor_time <- function(units) {
  switch(
    units,
    seconds = 1,
    minutes = 1 / 60,
    hours = 1 / (60 * 60),
    days = 1 / (60 * 60 * 24)
  )
}

get_factor_cpu <- function(units) {
  switch(
    units,
    percentage = 1,
    fraction = 1 / 100
  )
}

c("megabytes", "bytes", "kilobytes", "gigabytes")

get_factor_memory <- function(units) {
  switch(
    units,
    bytes = 1L,
    kilobytes = 1e-3,
    megabytes = 1e-6,
    gigabytes = 1e-9
  )
}
