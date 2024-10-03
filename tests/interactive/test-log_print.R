# Watch htop or task manager or activity monitor for CPU load during test.

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

path <- tempfile()
log_print(
  path = path,
  seconds = 2,
  pids = c(Sys.getpid(), process$get_pid())
)
log_read(path)
unlink(path)
