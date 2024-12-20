#include "timers.h"

#if SUPPORT_TIMERS

double seconds_current(void) {
  struct timespec time;
  if (clock_gettime(CLOCK_REALTIME, &time) == 0) {
    return (double) time.tv_sec + (double) time.tv_nsec / 1.0e9;
  } else {
    return 0.0;
  }
}

time_spec_t time_spec_init(
  const int seconds,
  const int nanoseconds
) {
  time_spec_t time_spec;
  time_spec.tv_sec = seconds;
  time_spec.tv_nsec = nanoseconds;
  return time_spec;
}

void sleep_interval(const time_spec_t time_spec) {
  nanosleep(&time_spec, NULL);
}

#elif OS_WINDOWS

time_spec_t time_spec_init(
  const int seconds,
  const int nanoseconds
) {
  time_spec_t time_spec;
  time_spec.milliseconds = (unsigned long) seconds * 1000ULL +
    (unsigned long) nanoseconds / 1000000ULL;
  return time_spec;
}

void sleep_interval(time_spec_t time_spec) {
  Sleep(time_spec.milliseconds);
}

#else

#include <windows.h>

double seconds_current(void) {
  LARGE_INTEGER frequency, counter;
  if (QueryPerformanceFrequency(&frequency) == 0) {
    return -1.0;
  }
  if (QueryPerformanceCounter(&counter) == 0) {
    return -1.0;
  }
  return (double) counter.QuadPart / (double) frequency.QuadPart;
}


double seconds_current(void) {
  struct timespec time;
  if (clock_gettime(CLOCK_REALTIME, &time) == 0) {
    return (double) time.tv_sec + (double) time.tv_nsec / 1.0e9;
  } else {
    return -1.0;
  }
}

time_spec_t time_spec_init(
  int seconds,
  int nanoseconds
) {
  return 0;
}

void sleep_interval(const time_spec_t time_spec) {
  return;
}

#endif
