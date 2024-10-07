/*
 * Based on the {ps} R package:
 * https://github.com/r-lib/ps/blob/main/src/api-linux.c
 * See the LICENSE.note file at the top level of this package for license and
 * copyright information relating to this code.
 */

#include "metrics.h"
#if WINDOWS

#define PSAPI_VERSION 1
#include <windows.h>
#include <psapi.h>

/*
 * According to
 * https://github.com/r-lib/ps/blob/dccc347d11554c55724e6f540d5001ded7bf80c7/src/api-windows.c#L602-L604,
 * GetActiveProcessorCount is available only on 64 bit versions
 * of Windows from Windows 7 onward.
 * Neither Windows Vista 64 bit nor Windows XP has it.
 */
int cpu_cores(void) {
  SYSTEM_INFO sysinfo;
  GetSystemInfo(&sysinfo);
  if (sysinfo.dwNumberOfProcessors > 0) {
    return sysinfo.dwNumberOfProcessors;
  } else {
    return 0;
  }
}

double cpu_seconds(FILETIME file_time) {
  ULARGE_INTEGER time;
  time.LowPart = file_time.dwLowDateTime;
  time.HighPart = file_time.dwHighDateTime;
  return ((double) time.QuadPart) / 1.0e7;
}

void metrics_system(metrics_t* metrics, const int pid) {
  PROCESS_MEMORY_COUNTERS counters;
  HANDLE handle = OpenProcess(
    PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_VM_READ,
    FALSE,
    pid
  );
  if (handle == NULL) {
    metrics->status = GetLastError();
    return;
  }
  if (GetProcessMemoryInfo(handle, &counters, sizeof(counters))) {
    metrics->bytes_resident = counters.WorkingSetSize;
    metrics->bytes_virtual = counters.PagefileUsage;
  } else {
    metrics->status = GetLastError();
  }
  double seconds = seconds_current();
  if (seconds > 0.0) {
    metrics->seconds_current = seconds;
  } else {
    metrics_reset_cumulative(metrics);
    metrics->status = ERROR_TIME;
    CloseHandle(handle);
    return;
  }
  FILETIME px_create, px_exit, px_kernel, px_user;
  double seconds_process;
  if (GetProcessTimes(handle, &px_create, &px_exit, &px_kernel, &px_user)) {
    seconds_process = cpu_seconds(px_user) + cpu_seconds(px_kernel);
  } else {
    metrics->status = GetLastError();
    CloseHandle(handle);
    return;
  }
  CloseHandle(handle);
  if (
    metrics->status == 0 &&
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
    cores = cpu_cores();
    if (cores < 1) {
      metrics->status = ERROR_SYSTEM;
      return;
    }
  }
  if (cores > 0) {
    metrics->percent_cpu = metrics->percent_core / cores;
  }
}

#endif
