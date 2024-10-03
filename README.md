# autometric <a href="https://wlandau.github.io/autometric/"><img src="man/figures/logo-readme.png" align="right" height="138" /></a>

<!--
[![CRAN](https://www.r-pkg.org/badges/version/autometric)](https://CRAN.R-project.org/package=autometric)
-->

[![status](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![check](https://github.com/wlandau/autometric/actions/workflows/check.yaml/badge.svg)](https://github.com/wlandau/autometric/actions?query=workflow%3Acheck)
[![codecov](https://codecov.io/gh/wlandau/autometric/branch/main/graph/badge.svg?token=3T5DlLwUVl)](https://app.codecov.io/gh/wlandau/autometric)
[![lint](https://github.com/wlandau/autometric/actions/workflows/lint.yaml/badge.svg)](https://github.com/wlandau/autometric/actions?query=workflow%3Alint)
[![pkgdown](https://github.com/wlandau/autometric/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/wlandau/autometric/actions?query=workflow%3Apkgdown)

Intense parallel workloads can be difficult to monitor. Packages [`crew.cluster`](https://wlandau.github.io/crew.cluster/), [`clustermq`](https://mschubert.github.io/clustermq/), and [`future.batchtools`](https://future.batchtools.futureverse.org/) distribute hundreds of worker processes over multiple computers. If a worker process exhausts its available memory, it may terminate silently, leaving the underlying problem difficult to detect or troubleshoot. Using the `autometric` package, a worker can proactively monitor itself in a detached POSIX thread. The worker process itself runs normally, and the thread writes to a log every few seconds. If the worker terminates unexpectedly, `autometric` can read and visualize the log file to reveal potential resource-related reasons for the crash.

## Requirements

* A Linux, Mac OS, or Windows operating system.
* POSIX threads. Modern tool chains seem to provide R with POSIX thread support, even on Windows.
* Either POSIX timers or a Windows operating system.

## Installation

You can install the development version of `autometric` from [GitHub](https://github.com/) with:

```r
remotes::install_github("wlandau/autometric")
```

## Usage

The `log_start()` function in `autometric` starts a non-blocking POSIX thread to write resource usage statistics to a log at periodic intervals. The following example uses the [`callr`](https://callr.r-lib.org/) R package to launch a resource-intensive background process on a Unix-like system. The `autometric` thread prints to standard output, and `callr` directs all its standard output to a temporary text file we define in advance.^[Logging to standard output is useful on clusters like SLURM where workers already redirect standard output to log files, or on the cloud where a service like [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) captures messages instead of directing them to a physical file.]

```r
log_file <- tempfile()

process <- callr::r_bg(
  func = function() {
    autometric::log_start(seconds = 1, path = "/dev/stdout")
  
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

When we read in the log file, we see messages from both R and the `autometric` thread.

```r
writeLines(readLines(log_file))
#> __AUTOMETRIC__|0.0.1|37662|0|1727807326.195|7.500|0.750|80068608|420423090176|__AUTOMETRIC__
#> [1] "Defining a function that guzzles CPU power."
#> [1] "Allocating a large object."
#> __AUTOMETRIC__|0.0.1|37662|0|1727807327.198|97.300|9.730|395264000|421223120896|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807328.203|100.000|10.000|715816960|421223120896|__AUTOMETRIC__
#> [1] "Guzzling CPU power."
#> __AUTOMETRIC__|0.0.1|37662|0|1727807329.208|100.000|10.000|904986624|421231509504|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807330.213|99.400|9.940|910573568|421239898112|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807331.218|99.600|9.960|922910720|421256675328|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807332.223|100.000|10.000|929873920|421256675328|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807333.228|99.900|9.990|937033728|421256675328|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807334.233|100.000|10.000|937066496|421256675328|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807335.238|100.000|10.000|937115648|421256675328|__AUTOMETRIC__
#> [1] "Allocating another large object."
#> __AUTOMETRIC__|0.0.1|37662|0|1727807336.243|100.000|10.000|1252573184|422056689664|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807337.249|100.000|10.000|1571487744|422056689664|__AUTOMETRIC__
#> [1] "Guzzling more CPU."
#> __AUTOMETRIC__|0.0.1|37662|0|1727807338.254|100.000|10.000|1253179392|422056689664|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807339.259|100.000|10.000|1253179392|422056689664|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807340.264|99.300|9.930|1193918464|422056689664|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807341.269|100.000|10.000|1193918464|422056689664|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807342.274|100.000|10.000|1193918464|422056689664|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807343.279|100.000|10.000|1198129152|422056689664|__AUTOMETRIC__
#> [1] "Allocating a third large object."
#> __AUTOMETRIC__|0.0.1|37662|0|1727807344.284|100.000|10.000|1203765248|422856704000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807345.288|99.500|9.950|968916992|422856704000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807346.293|99.300|9.930|1050394624|422856704000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|37662|0|1727807347.298|91.500|9.150|911818752|422857752576|__AUTOMETRIC__
#> Done.
```

`autometric` knows how to read its log entries even if the log file has other messages. See the documentation of `log_read()` to learn how to interpret the data and customize the measurement units.

```r
library(autometric)
log_data <- log_read(log_file)

log_data
#>    version   pid status   time  core   cpu   resident  virtual
#> 1    0.0.1 37662      0  0.000   7.5  0.75   80.06861 420423.1
#> 2    0.0.1 37662      0  1.003  97.3  9.73  395.26400 421223.1
#> 3    0.0.1 37662      0  2.008 100.0 10.00  715.81696 421223.1
#> 4    0.0.1 37662      0  3.013 100.0 10.00  904.98662 421231.5
#> 5    0.0.1 37662      0  4.018  99.4  9.94  910.57357 421239.9
#> 6    0.0.1 37662      0  5.023  99.6  9.96  922.91072 421256.7
#> 7    0.0.1 37662      0  6.028 100.0 10.00  929.87392 421256.7
#> 8    0.0.1 37662      0  7.033  99.9  9.99  937.03373 421256.7
#> 9    0.0.1 37662      0  8.038 100.0 10.00  937.06650 421256.7
#> 10   0.0.1 37662      0  9.043 100.0 10.00  937.11565 421256.7
#> 11   0.0.1 37662      0 10.048 100.0 10.00 1252.57318 422056.7
#> 12   0.0.1 37662      0 11.054 100.0 10.00 1571.48774 422056.7
#> 13   0.0.1 37662      0 12.059 100.0 10.00 1253.17939 422056.7
#> 14   0.0.1 37662      0 13.064 100.0 10.00 1253.17939 422056.7
#> 15   0.0.1 37662      0 14.069  99.3  9.93 1193.91846 422056.7
#> 16   0.0.1 37662      0 15.074 100.0 10.00 1193.91846 422056.7
#> 17   0.0.1 37662      0 16.079 100.0 10.00 1193.91846 422056.7
#> 18   0.0.1 37662      0 17.084 100.0 10.00 1198.12915 422056.7
#> 19   0.0.1 37662      0 18.089 100.0 10.00 1203.76525 422856.7
#> 20   0.0.1 37662      0 19.093  99.5  9.95  968.91699 422856.7
#> 21   0.0.1 37662      0 20.098  99.3  9.93 1050.39462 422856.7
#> 22   0.0.1 37662      0 21.103  91.5  9.15  911.81875 422857.8
```

`autometric` also supports simple visualizations plot performance metrics over time. To avoid depending on many other R packages, `autometric` only uses base plotting functionality. Feel free to create fancier visualizations directly with [`ggplot2`](https://ggplot2.tidyverse.org/).

```r
log_plot(log_data, metric = "cpu")
```

![](./man/figures/cpu.png)

```r
log_plot(log_data, metric = "resident")
```

![](./man/figures/resident.png)

## Attribution

`autometric` heavily leverages fantastic work on the [`ps`](https://ps.r-lib.org/) R package by Jay Loden, Dave Daeschler, Giampaolo Rodola, Gábor Csárdi, and Posit Software, PBC. The source code of [`ps`](https://ps.r-lib.org/) was especially helpful for identifying appropriate system calls to retrieve resource usage statistics. Attribution is given in the NOTICE file and in the comments of the C files in `src/`. Please visit <https://github.com/r-lib/ps/blob/main/LICENSE.md> to view the license of [`ps`](https://ps.r-lib.org/). [`ps`](https://ps.r-lib.org/) in turn is based on [`psutil`](https://github.com/giampaolo/psutil), whose license is available at <https://github.com/giampaolo/psutil/blob/master/LICENSE>.

## Code of Conduct

Please note that the `autometric` project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
