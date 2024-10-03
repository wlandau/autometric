#ifndef TIMERS_H
#define TIMERS_H

#include "support.h"

#if TIMERS

typedef struct timespec time_spec_t;

#elif WINDOWS

#include <windows.h>

typedef struct {
  unsigned long milliseconds;
} time_spec_t;

#else

typedef int time_spec_t;

#endif

double seconds_current(void);
void sleep_interval(const time_spec_t time_spec);
time_spec_t time_spec_init(const int seconds, const int nanoseconds);

#endif
