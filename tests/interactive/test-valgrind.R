# R -d "valgrind --leak-check=full" --no-save -f tests/interactive/test-valgrind.R # nolint
library(autometric)

local({
  temp <- log_support()
  temp <- log_version()
  path <- tempfile()
  log_print(path = path, seconds = 0.5)
  temp <- log_active()
  log_start(path = path, seconds = 0.5)
  temp <- log_active()
  Sys.sleep(2)
  log_stop()
  temp <- log_active()
  temp <- log_read(path)
  Sys.sleep(2)
})
