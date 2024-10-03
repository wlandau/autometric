/*
 * Based on ps__get_status() from the {ps} R package:
 * https://github.com/r-lib/ps/blob/dccc347d11554c55724e6f540d5001ded7bf80c7/src/api-macos.c#L78-L152
 * See the NOTICE file at the top level of this package for license and
 * copyright information relating to this code.
 * The authors of {ps} credit these sources:
 * http://stackoverflow.com/questions/6788274/ios-mac-cpu-usage-for-thread and
 * https://github.com/max-horvath/htop-osx/blob/e86692e869e30b0bc7264b3675d2a4014866ef46/ProcessList.c
 */

#include "metrics.h"
#if MAC

#include <stdio.h>
#include <mach/mach.h>
#include <mach/task_info.h>
#include <sys/sysctl.h>
#include "timers.h"
#include <unistd.h>

int cpu_cores(void) {
  int cores;
  size_t size = sizeof(cores);
  if (sysctlbyname("hw.logicalcpu", &cores, &size, NULL, 0) == 0) {
    return cores;
  } else {
    return 0;
  }
}

void metrics_system(metrics_t* metrics, const int pid) {
  double seconds = seconds_current();
  if (seconds > 0.0) {
    metrics->seconds_current = seconds;
  } else {
    metrics_reset_cumulative(metrics);
    metrics->status = ERROR_TIME;
    return;
  }
  kern_return_t status;
  task_t task;
  status = task_for_pid(mach_task_self(), pid, &task);
  if (status != KERN_SUCCESS) {
    metrics->status = (int) status;
    return;
  }
  struct task_basic_info info_task;
  mach_msg_type_number_t task_info_count = TASK_BASIC_INFO_COUNT;
  status = task_info(
    task,
    TASK_BASIC_INFO,
    (task_info_t) &info_task,
    &task_info_count
  );
  if (status != KERN_SUCCESS) {
    metrics->status = (int) status;
    return;
  }
  metrics->bytes_resident = info_task.resident_size;
  metrics->bytes_virtual = info_task.virtual_size;
  thread_array_t thread_list;
  mach_msg_type_number_t thread_count;
  status = task_threads(task, &thread_list, &thread_count);
  if (status != KERN_SUCCESS) {
    mach_port_deallocate(mach_task_self(), task);
    metrics->status = (int) status;
    return;
  }
  metrics->percent_cpu = 0;
  for (unsigned int i = 0; i < thread_count; i++) {
    thread_info_data_t info_thread;
    mach_msg_type_number_t thread_info_count = THREAD_BASIC_INFO_COUNT;
    status = thread_info(
      thread_list[i],
      THREAD_BASIC_INFO,
      (thread_info_t) info_thread,
      &thread_info_count
    );
    if (status == KERN_SUCCESS) {
      thread_basic_info_t info_basic = (thread_basic_info_t) info_thread;
      metrics->percent_core += 100.0 * ((double) info_basic->cpu_usage) /
        TH_USAGE_SCALE;
      mach_port_deallocate(mach_task_self(), thread_list[i]);
    }
  }
  vm_deallocate(
    mach_task_self(),
    (vm_address_t) thread_list,
    sizeof(thread_port_array_t) * thread_count
  );
  mach_port_deallocate(mach_task_self(), task);
  static int cores = 0;
  if (cores <= 0) {
    cores = cpu_cores();
  }
  if (cores < 1) {
    metrics->status = ERROR_SYSTEM;
    return;
  }
  metrics->percent_cpu = metrics->percent_core / cores;
  return;
}

#endif
