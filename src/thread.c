#include "support.h"

#if SUPPORT
#include "thread.h"

pthread_mutex_t run_mutex = PTHREAD_MUTEX_INITIALIZER;
int run_flag = 0;
char run_phase[PHASE_N] = PHASE_DEFAULT;

pthread_args_t* pthread_args_init(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP names,
  SEXP n_pids
) {
  pthread_args_t* args = (pthread_args_t*) malloc(sizeof(pthread_args_t));
  if (args == NULL) {
    return NULL;
  }
  const char* path_ = CHAR(STRING_ELT(path, 0));
  args->path = (char*) malloc((strlen(path_) + 1) * sizeof(char));
  if (args->path == NULL) {
    free(args);
    return NULL;
  }
  strcpy(args->path, CHAR(STRING_ELT(path, 0)));
  args->seconds = INTEGER(seconds)[0];
  args->nanoseconds = INTEGER(nanoseconds)[0];
  args->n_pids = INTEGER(n_pids)[0];
  args->pids = (int*) malloc(args->n_pids * sizeof(int));
  if (args->pids == NULL) {
    free((void*) args->path);
    free((void*) args->pids);
    free(args);
    return NULL;
  }
  memcpy(args->pids,  INTEGER(pids), args->n_pids * sizeof(int));
  char** names_ = (char**) malloc(args->n_pids * sizeof(char*));
  if (names_ == NULL) {
    free((void*) args->path);
    free((void*) args->pids);
    free(args);
    return NULL;
  }
  for (int i = 0; i < args->n_pids; ++i) {
    const char* name = CHAR(STRING_ELT(names, i));
    names_[i] = (char*) malloc((strlen(name) + 1) * sizeof(char));
    if (names_[i] == NULL) {
      for (int j = 0; j < i; ++j) {
        free(names_[j]);
      }
      free(names_);
      free((void*) args->path);
      free((void*) args->pids);
      free(args);
      return NULL;
    }
    strcpy(names_[i], name);
  }
  args->names = names_;
  return args;
}

void pthread_args_free(pthread_args_t* args) {
  free((void*) args->path);
  free((void*) args->pids);
  for (int i = 0; i < args->n_pids; ++i) {
    free(args->names[i]);
  }
  free(args->names);
  free(args);
}

void pthread_phase_get(char* phase) {
  pthread_mutex_lock(&run_mutex);
  strcpy(phase, run_phase);
  pthread_mutex_unlock(&run_mutex);
}

void pthread_phase_reset(void) {
  pthread_mutex_lock(&run_mutex);
  strcpy(run_phase, PHASE_DEFAULT);
  pthread_mutex_unlock(&run_mutex);
}

void pthread_phase_set(const char* phase) {
  pthread_mutex_lock(&run_mutex);
  strncpy(run_phase, phase, sizeof(run_phase));
  run_phase[sizeof(run_phase) - 1] = '\0';
  pthread_mutex_unlock(&run_mutex);
}

int pthread_run_flag_get(void) {
  int out;
  pthread_mutex_lock(&run_mutex);
  out = run_flag;
  pthread_mutex_unlock(&run_mutex);
  return out;
}

void* pthread_run(void* arg) {
  char phase[PHASE_N];
  pthread_args_t* args = (pthread_args_t*) arg;
  time_spec_t sleep_spec = time_spec_init(args->seconds, args->nanoseconds);
  metrics_t* metrics_array = metrics_array_init(args->n_pids);
  if (metrics_array == NULL) {
    free(metrics_array);
    return NULL;
  }
  for (int i = 0; i < args->n_pids; ++i) {
    metrics_iteration(metrics_array + i, args->path, args->pids[i]);
  }
  while (1) {
    sleep_interval(sleep_spec);
    if (!pthread_run_flag_get()) {
      break;
    }
    pthread_phase_get(phase);
    for (int i = 0; i < args->n_pids; ++i) {
      metrics_iteration(metrics_array + i, args->path, args->pids[i]);
      metrics_print(
        metrics_array + i,
        args->path,
        args->pids[i],
        args->names[i],
        phase
      );
    }
  }
  pthread_args_free(args);
  free(metrics_array);
  return NULL;
}

void pthread_start(pthread_args_t* args) {
  pthread_mutex_lock(&run_mutex);
  if (run_flag) {
    pthread_mutex_unlock(&run_mutex);
    pthread_args_free(args);
    return;
  }
  pthread_t thread;
  if (pthread_create(&thread, NULL, pthread_run, args)) {
    pthread_args_free(args);
  } else {
    pthread_detach(thread);
    run_flag = 1;
  }
  pthread_mutex_unlock(&run_mutex);
}

void pthread_stop(void) {
  pthread_mutex_lock(&run_mutex);
  run_flag = 0;
  pthread_mutex_unlock(&run_mutex);
}

#endif
