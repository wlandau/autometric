# Watch htop or task manager or activity monitor for CPU load during test.
library(autometric)

local({
  log_stop()
  stopifnot(isFALSE(log_active()))
  out <- FALSE
  out <- tryCatch(
    log_start(path = "/etc/test"),
    error = function(condition) TRUE
  )
  stopifnot(isTRUE(out))
  stopifnot(isFALSE(log_active()))
})

local({
  process <- callr::r_bg(
    function() {
      is_prime <- function(n) {
        if (n <= 1) return(FALSE)
        for (i in seq(2, sqrt(n))) {
          if (n %% i == 0) {
            return(FALSE)
          }
        }
        TRUE
      }
      lapply(seq_len(1e6), is_prime)
      invisible()
    }
  )
  message(Sys.getpid())
  message(process$get_pid())
  library(autometric)
  path <- tempfile()
  log_start(
    path = path,
    seconds = 0.5,
    pids = c(Sys.getpid(), process$get_pid())
  )
  Sys.sleep(2)
  log_stop()
  print(log_read(path))
  unlink(path)
  Sys.sleep(2)
})
