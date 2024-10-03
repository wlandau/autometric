#include "metrics.h"

metrics_t* metrics_array_init(int n) {
  metrics_t* metrics_array = (metrics_t*) malloc(n * sizeof(metrics_t));
  if (metrics_array == NULL) {
    free(metrics_array);
    return NULL;
  }
  for (int i = 0; i < n; ++i) {
    metrics_reset_cumulative(metrics_array + i);
    metrics_reset_memoryless(metrics_array + i);
  }
  return metrics_array;
}

void metrics_iteration(metrics_t* metrics, const char* path, const int pid) {
  metrics_reset_memoryless(metrics);
  metrics_system(metrics, pid);
}

void metrics_print(
  const metrics_t* metrics,
  const char* path,
  const int pid,
  const char* name
) {
  FILE* file = fopen(path, "a");
  if (file == NULL) {
    return;
  }
  fprintf(
    file,
    "__AUTOMETRIC__|%s|%d|%s|%d|%.3f|%.3f|%.3f|%lu|%lu|__AUTOMETRIC__\n",
    VERSION,
    pid,
    name,
    metrics->status,
    metrics->seconds_current,
    metrics->percent_core,
    metrics->percent_cpu,
    metrics->bytes_resident,
    metrics->bytes_virtual
  );
  fclose(file);
}

void metrics_reset_cumulative(metrics_t* metrics) {
  metrics->seconds_current = 0.0;
  metrics->seconds_previous = 0.0;
  metrics->seconds_process = 0.0;
}

void metrics_reset_memoryless(metrics_t* metrics) {
  metrics->bytes_resident = 0;
  metrics->bytes_virtual = 0;
  metrics->percent_core = 0.0;
  metrics->percent_cpu = 0.0;
  metrics->status = 0;
}
