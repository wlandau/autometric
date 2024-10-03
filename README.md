
# autometric <a href="https://wlandau.github.io/autometric/"><img src="man/figures/logo-readme.png" align="right" height="138" /></a>

<!--
[![CRAN](https://www.r-pkg.org/badges/version/autometric)](https://CRAN.R-project.org/package=autometric)
-->

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
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985463.531|19.900|1.990|78168064|420423090176|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985464.533|0.800|0.080|78184448|420423090176|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985465.539|0.000|0.000|78217216|420431478784|__AUTOMETRIC__
#> [1] "Defining a function that guzzles CPU power."
#> [1] "Allocating a large object."
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985466.544|0.000|0.000|78233600|420431478784|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985467.550|96.700|9.670|379420672|421231509504|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985468.555|100.000|10.000|697237504|421239898112|__AUTOMETRIC__
#> [1] "Guzzling CPU power."
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985469.560|99.300|9.930|895926272|421382504448|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985470.565|99.900|9.990|909918208|421390893056|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985471.568|100.000|10.000|914718720|421390893056|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985472.573|99.300|9.930|924172288|421390893056|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985473.577|98.800|9.880|926072832|421390893056|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985474.582|99.100|9.910|926646272|421390893056|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985475.587|97.700|9.770|930643968|421399281664|__AUTOMETRIC__
#> [1] "Allocating another large object."
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985476.589|100.000|10.000|1105592320|422199296000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985477.594|99.100|9.910|1426571264|422199296000|__AUTOMETRIC__
#> [1] "Guzzling more CPU."
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985478.599|100.000|10.000|1735507968|422199296000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985479.604|100.000|10.000|1737244672|422199296000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985480.605|100.000|10.000|1737244672|422199296000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985481.611|98.700|9.870|1737244672|422199296000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985482.616|100.000|10.000|1737244672|422199296000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985483.621|99.400|9.940|1737244672|422199296000|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985484.626|98.200|9.820|1737244672|422199296000|__AUTOMETRIC__
#> [1] "Allocating a third large object."
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985485.631|100.000|10.000|1854226432|422999310336|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985486.637|99.000|9.900|2173042688|422999310336|__AUTOMETRIC__
#> __AUTOMETRIC__|0.0.1|43300|my_worker|0|1727985487.642|100.000|10.000|2493399040|422999310336|__AUTOMETRIC__
#> [1] "Done."
```

`autometric` knows how to read its log entries even if the log file has
other messages. See the documentation of `log_read()` to learn how to
interpret the data and customize the measurement units.

``` r
library(autometric)
log_data <- log_read(log_file)

log_data
#>    version   pid      name status   time  core   cpu   resident  virtual
#> 1    0.0.1 43300 my_worker      0  0.000  19.9  1.99   78.16806 420423.1
#> 2    0.0.1 43300 my_worker      0  1.002   0.8  0.08   78.18445 420423.1
#> 3    0.0.1 43300 my_worker      0  2.008   0.0  0.00   78.21722 420431.5
#> 4    0.0.1 43300 my_worker      0  3.013   0.0  0.00   78.23360 420431.5
#> 5    0.0.1 43300 my_worker      0  4.019  96.7  9.67  379.42067 421231.5
#> 6    0.0.1 43300 my_worker      0  5.024 100.0 10.00  697.23750 421239.9
#> 7    0.0.1 43300 my_worker      0  6.029  99.3  9.93  895.92627 421382.5
#> 8    0.0.1 43300 my_worker      0  7.034  99.9  9.99  909.91821 421390.9
#> 9    0.0.1 43300 my_worker      0  8.037 100.0 10.00  914.71872 421390.9
#> 10   0.0.1 43300 my_worker      0  9.042  99.3  9.93  924.17229 421390.9
#> 11   0.0.1 43300 my_worker      0 10.046  98.8  9.88  926.07283 421390.9
#> 12   0.0.1 43300 my_worker      0 11.051  99.1  9.91  926.64627 421390.9
#> 13   0.0.1 43300 my_worker      0 12.056  97.7  9.77  930.64397 421399.3
#> 14   0.0.1 43300 my_worker      0 13.058 100.0 10.00 1105.59232 422199.3
#> 15   0.0.1 43300 my_worker      0 14.063  99.1  9.91 1426.57126 422199.3
#> 16   0.0.1 43300 my_worker      0 15.068 100.0 10.00 1735.50797 422199.3
#> 17   0.0.1 43300 my_worker      0 16.073 100.0 10.00 1737.24467 422199.3
#> 18   0.0.1 43300 my_worker      0 17.074 100.0 10.00 1737.24467 422199.3
#> 19   0.0.1 43300 my_worker      0 18.080  98.7  9.87 1737.24467 422199.3
#> 20   0.0.1 43300 my_worker      0 19.085 100.0 10.00 1737.24467 422199.3
#> 21   0.0.1 43300 my_worker      0 20.090  99.4  9.94 1737.24467 422199.3
#> 22   0.0.1 43300 my_worker      0 21.095  98.2  9.82 1737.24467 422199.3
#> 23   0.0.1 43300 my_worker      0 22.100 100.0 10.00 1854.22643 422999.3
#> 24   0.0.1 43300 my_worker      0 23.106  99.0  9.90 2173.04269 422999.3
#> 25   0.0.1 43300 my_worker      0 24.111 100.0 10.00 2493.39904 422999.3
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
Attribution is given in the NOTICE file and in the comments of the C
files in `src/`. Please visit
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
