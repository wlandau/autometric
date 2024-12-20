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

get_factor_size <- function(units) {
  switch(
    units,
    bytes = 1L,
    kilobytes = 1e-3,
    megabytes = 1e-6,
    gigabytes = 1e-9
  )
}
