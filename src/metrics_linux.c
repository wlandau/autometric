/*
 * Based on the {ps} R package:
 * https://github.com/r-lib/ps/blob/main/src/api-linux.c
 * See the NOTICE file at the top level of this package for license and
 * copyright information relating to this code.
 */

#include "metrics.h"
#if LINUX

#include <string.h>
#include <sys/sysinfo.h>

void metrics_system(metrics_t* metrics, const int pid) {
  char path[512];
  int size = snprintf(path, sizeof(path), "/proc/%d/stat", pid);
  if (size < 0 || size >= sizeof(path)) {
    metrics->status = ERROR_BUFFER;
    return;
  }
  char buffer[2048];
  FILE *file = fopen(path, "r");
  if (file == NULL) {
    metrics->status = ERROR_FILE;
    return;
  }
  if (fgets(buffer, sizeof(buffer), file) == NULL) {
    metrics->status = ERROR_BUFFER;
    fclose(file);
    return;
  }
  fclose(file);
  char* place = strchr(buffer, '\n');
  if (place == NULL) {
    metrics->status = ERROR_BUFFER;
    return;
  }
  *place = '\0';
  place = strrchr(buffer, ')');
  if (place == NULL || strchr(buffer, '(') == NULL) {
    metrics->status = ERROR_BUFFER;
    return;
  }
  double seconds = seconds_current();
  if (seconds > 0.0) {
    metrics->seconds_current = seconds;
  } else {
    metrics_reset_cumulative(metrics);
    metrics->status = ERROR_TIME;
    return;
  }
  char state;
  int ppid, pgrp, session, tty_nr, tpgid;
  unsigned flags;
  unsigned long minflt, cminflt, majflt, cmajflt, utime, stime;
  long cutime, cstime, priority, nice, num_threads, itrealvalue;
  unsigned long long starttime;
  unsigned long vsize;
  long rss;
  // c.f. https://linux.die.net/man/5/proc
  size = sscanf(
    place + 2,
    "%c %d %d %d %d %d %u %lu %lu %lu %lu %lu %lu %ld %ld %ld %ld %ld %ld %llu %lu %ld",
    &state,
    &ppid, &pgrp, &session, &tty_nr, &tpgid,
    &flags,
    &minflt, &cminflt, &majflt, &cmajflt, &utime, &stime,
    &cutime, &cstime, &priority, &nice, &num_threads, &itrealvalue,
    &starttime,
    &vsize,
    &rss
  );
  if (size != 22) {
    metrics->status = ERROR_READ;
    return;
  }
  metrics->bytes_resident = rss * ((unsigned long) sysconf(_SC_PAGESIZE));
  metrics->bytes_virtual = vsize;
  // c.f. https://man7.org/linux/man-pages/man3/sysconf.3.html
  double ticks_per_second = sysconf(_SC_CLK_TCK);
  double seconds_process = ((double) utime / ticks_per_second) +
    ((double) stime / ticks_per_second);
  if (
    metrics->status == 0 &&
      metrics->seconds_current > 0.0 &&
      metrics->seconds_previous > 0.0 &&
      metrics->seconds_process > 0.0 &&
      metrics->seconds_current > metrics->seconds_previous
  ) {
    metrics->percent_core = 100.0 *
      (seconds_process - metrics->seconds_process) /
      (metrics->seconds_current - metrics->seconds_previous);
  } else {
    metrics->status = ERROR_ARITHMETIC;
  }
  metrics->seconds_previous = metrics->seconds_current;
  metrics->seconds_process = seconds_process;
  static int cores = 0;
  if (cores <= 0) {
    cores = get_nprocs_conf();
  }
  if (cores < 1) {
    metrics->status = ERROR_SYSTEM;
    return;
  }
  metrics->percent_cpu = metrics->percent_core / cores;
}

#endif
