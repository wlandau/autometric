
# autometric <a href="https://wlandau.github.io/autometric/"><img src="man/figures/logo-readme.png" align="right" height="138" /></a>

[![CRAN](https://www.r-pkg.org/badges/version/autometric)](https://CRAN.R-project.org/package=autometric)
[![status](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![check](https://github.com/wlandau/autometric/actions/workflows/check.yaml/badge.svg)](https://github.com/wlandau/autometric/actions?query=workflow%3Acheck)
[![codecov](https://codecov.io/gh/wlandau/autometric/branch/main/graph/badge.svg?token=3T5DlLwUVl)](https://app.codecov.io/gh/wlandau/autometric)
[![lint](https://github.com/wlandau/autometric/actions/workflows/lint.yaml/badge.svg)](https://github.com/wlandau/autometric/actions?query=workflow%3Alint)
[![pkgdown](https://github.com/wlandau/autometric/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/wlandau/autometric/actions?query=workflow%3Apkgdown)

Intense parallel workloads can be difficult to monitor. Packages
[`crew.cluster`](https://wlandau.github.io/crew.cluster/),
[`clustermq`](https://mschubert.github.io/clustermq/), and
[`future.batchtools`](https://future.batchtools.futureverse.org/)
distribute hundreds of worker processes over multiple computers. If a
worker process exhausts its available memory, it may terminate silently,
leaving the underlying problem difficult to detect or troubleshoot.
Using the `autometric` package, a worker can proactively monitor itself
in a detached POSIX thread. The worker process itself runs normally, and
the thread writes to a log every few seconds. If the worker terminates
unexpectedly, `autometric` can read and visualize the log file to reveal
potential resource-related reasons for the crash.

## Requirements

- A Linux, Mac OS, or Windows operating system.
- POSIX threads. Modern tool chains seem to provide R with POSIX thread
  support, even on Windows.
- Either POSIX timers or a Windows operating system.

## Installation

You can install the development version of `autometric` from
[GitHub](https://github.com/) with:

``` r
remotes::install_github("wlandau/autometric")
```

## Usage

The `log_start()` function in `autometric` starts a non-blocking POSIX
thread to write resource usage statistics to a log at periodic
intervals. The following example uses the
[`callr`](https://callr.r-lib.org/) R package to launch a
resource-intensive background process on a Unix-like system. The
`autometric` thread prints to standard output, and `callr` directs all
its standard output to a temporary text file we define in advance.[^1]

``` r
log_file <- tempfile()

process <- callr::r_bg(
  func = function() {
    print("Setting up the log.")
    autometric::log_start(
      path = "/dev/stdout",
      pids = c(my_worker = Sys.getpid()),
      seconds = 1
    )
    
    print("Warming up.")
    Sys.sleep(3)
    
    print("Defining a function that guzzles CPU power.")
    is_prime <- function(n) {
      if (n <= 1) return(FALSE)
      for (i in seq(2, sqrt(n))) {
        if (n %% i == 0) {
          return(FALSE)
        }
      }
      TRUE
    }
    
    print("Allocating a large object.")
    x <- rnorm(1e8)
    
    print("Guzzling CPU power.")
    lapply(seq_len(1e6), is_prime)
    
    print("Allocating another large object.")
    y <- rnorm(1e8)
    
    print("Guzzling more CPU.")
    lapply(seq_len(1e6), is_prime)
    
    print("Allocating a third large object.")
    z <- rnorm(1e8)
    
    print("Done.")
  },
  stdout = log_file
)
```

When we read in the log file, we see messages from both R and the
`autometric` thread.

``` r
writeLines(readLines(log_file))
#> [1] "Setting up the log."
#> [1] "Warming up."
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590201.166|1.000|0.100|76005376|420621271040|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590202.174|0.000|0.000|76021760|420621271040|__AUTOMETRIC__
#> [1] "Defining a function that guzzles CPU power."
#> [1] "Allocating a large object."
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590203.177|0.000|0.000|76038144|420621271040|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590204.182|95.400|9.540|379813888|421421301760|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590205.187|100.000|10.000|693846016|421421301760|__AUTOMETRIC__
#> [1] "Guzzling CPU power."
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590206.192|96.300|9.630|894943232|421555519488|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590207.194|99.100|9.910|914997248|421563908096|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590208.199|99.400|9.940|915963904|421563908096|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590209.204|100.000|10.000|929775616|421563908096|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590210.210|99.200|9.920|937164800|421563908096|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590211.215|99.900|9.990|937164800|421563908096|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590212.220|100.000|10.000|937164800|421563908096|__AUTOMETRIC__
#> [1] "Allocating another large object."
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590213.225|100.000|10.000|1118781440|422363922432|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590214.226|93.800|9.380|1045135360|422363922432|__AUTOMETRIC__
#> [1] "Guzzling more CPU."
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590215.231|99.100|9.910|1246822400|422363922432|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590216.236|100.000|10.000|1202110464|422363922432|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590217.242|98.200|9.820|1202159616|422363922432|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590218.247|99.700|9.970|1202159616|422363922432|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590219.252|100.000|10.000|1202159616|422363922432|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590220.257|99.900|9.990|1162248192|422363922432|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590221.262|98.700|9.870|1162248192|422363922432|__AUTOMETRIC__
#> [1] "Allocating a third large object."
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590222.268|100.000|10.000|1184382976|423163936768|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590223.271|99.400|9.940|1280753664|423163936768|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.5.9000|20624|my_worker|0|1728590224.276|100.000|10.000|1241595904|423163936768|__AUTOMETRIC__
#> [1] "Done."
```

`autometric` knows how to read its log entries even if the log file has
other messages. See the documentation of `log_read()` to learn how to
interpret the data and customize the measurement units.

``` r
library(autometric)
log_data <- log_read(log_file)

log_data
#>       version   pid      name status   time  core   cpu   resident  virtual
#> 1  0.0.5.9000 20624 my_worker      0  0.000   1.0  0.10   76.00538 420621.3
#> 2  0.0.5.9000 20624 my_worker      0  1.008   0.0  0.00   76.02176 420621.3
#> 3  0.0.5.9000 20624 my_worker      0  2.011   0.0  0.00   76.03814 420621.3
#> 4  0.0.5.9000 20624 my_worker      0  3.016  95.4  9.54  379.81389 421421.3
#> 5  0.0.5.9000 20624 my_worker      0  4.021 100.0 10.00  693.84602 421421.3
#> 6  0.0.5.9000 20624 my_worker      0  5.026  96.3  9.63  894.94323 421555.5
#> 7  0.0.5.9000 20624 my_worker      0  6.028  99.1  9.91  914.99725 421563.9
#> 8  0.0.5.9000 20624 my_worker      0  7.033  99.4  9.94  915.96390 421563.9
#> 9  0.0.5.9000 20624 my_worker      0  8.038 100.0 10.00  929.77562 421563.9
#> 10 0.0.5.9000 20624 my_worker      0  9.044  99.2  9.92  937.16480 421563.9
#> 11 0.0.5.9000 20624 my_worker      0 10.049  99.9  9.99  937.16480 421563.9
#> 12 0.0.5.9000 20624 my_worker      0 11.054 100.0 10.00  937.16480 421563.9
#> 13 0.0.5.9000 20624 my_worker      0 12.059 100.0 10.00 1118.78144 422363.9
#> 14 0.0.5.9000 20624 my_worker      0 13.060  93.8  9.38 1045.13536 422363.9
#> 15 0.0.5.9000 20624 my_worker      0 14.065  99.1  9.91 1246.82240 422363.9
#> 16 0.0.5.9000 20624 my_worker      0 15.070 100.0 10.00 1202.11046 422363.9
#> 17 0.0.5.9000 20624 my_worker      0 16.076  98.2  9.82 1202.15962 422363.9
#> 18 0.0.5.9000 20624 my_worker      0 17.081  99.7  9.97 1202.15962 422363.9
#> 19 0.0.5.9000 20624 my_worker      0 18.086 100.0 10.00 1202.15962 422363.9
#> 20 0.0.5.9000 20624 my_worker      0 19.091  99.9  9.99 1162.24819 422363.9
#> 21 0.0.5.9000 20624 my_worker      0 20.096  98.7  9.87 1162.24819 422363.9
#> 22 0.0.5.9000 20624 my_worker      0 21.102 100.0 10.00 1184.38298 423163.9
#> 23 0.0.5.9000 20624 my_worker      0 22.105  99.4  9.94 1280.75366 423163.9
#> 24 0.0.5.9000 20624 my_worker      0 23.110 100.0 10.00 1241.59590 423163.9
```

`autometric` also supports simple visualizations plot performance
metrics over time. To avoid depending on many other R packages,
`autometric` only uses base plotting functionality. Feel free to create
fancier visualizations directly with
[`ggplot2`](https://ggplot2.tidyverse.org/).

``` r
log_plot(log_data, metric = "cpu")
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />

``` r
log_plot(log_data, metric = "resident")
```

<img src="man/figures/README-unnamed-chunk-8-1.png" width="100%" />

## Attribution

`autometric` heavily leverages fantastic work on the
[`ps`](https://ps.r-lib.org/) R package by Jay Loden, Dave Daeschler,
Giampaolo Rodola, Gábor Csárdi, and Posit Software, PBC. The source code
of [`ps`](https://ps.r-lib.org/) was especially helpful for identifying
appropriate system calls to retrieve resource usage statistics.
Attribution is given in the `Authors@R` field of the `DESCRIPTION` file,
the `LICENSE.note` file at the top level of the package, and in the
comments of the C files in `src/`. Please visit
<https://github.com/r-lib/ps/blob/main/LICENSE.md> to view the license
of [`ps`](https://ps.r-lib.org/). [`ps`](https://ps.r-lib.org/) in turn
is based on [`psutil`](https://github.com/giampaolo/psutil), whose
license is available at
<https://github.com/giampaolo/psutil/blob/master/LICENSE>.

## Code of Conduct

Please note that the `autometric` project is released with a
[Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.

[^1]: Logging to standard output is useful on clusters like SLURM where
    workers already redirect standard output to log files, or on the
    cloud where a service like [Amazon
    CloudWatch](https://aws.amazon.com/cloudwatch/) captures messages
    instead of directing them to a physical file.
