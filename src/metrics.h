#ifndef METRICS_H
#define METRICS_H

#include "error.h"
#include "timers.h"
#include <stdio.h>
#include <stdlib.h>
#include "support.h"
#include "version.h"

typedef struct {
  unsigned long bytes_resident;
  unsigned long bytes_virtual;
  double percent_core;
  double percent_cpu;
  double seconds_current;
  double seconds_previous;
  double seconds_process;
  int status;
} metrics_t;

metrics_t* metrics_array_init(int n);
void metrics_iteration(metrics_t* metrics, const char* path, const int pid);
void metrics_print(
  const metrics_t* metrics,
  const char* path,
  const int pid,
  const char* name,
  const char* phase
);
void metrics_reset_cumulative(metrics_t* metrics);
void metrics_reset_memoryless(metrics_t* metrics);
void metrics_system(metrics_t* metrics, const int pid);

#endif
