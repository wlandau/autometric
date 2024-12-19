#include "log.h"
#include "support.h"
#if SUPPORT_LOG

#include "metrics.h"
#include "thread.h"

SEXP log_active(void) {
  return ScalarLogical(pthread_run_flag_get());
}

SEXP log_phase_get(void) {
  char phase[PHASE_N];
  pthread_phase_get(phase);
  SEXP out = PROTECT(mkString(phase));
  UNPROTECT(1);
  return out;
}

SEXP log_phase_reset(void) {
  pthread_phase_reset();
  return R_NilValue;
}

SEXP log_phase_set(SEXP phase) {
  pthread_phase_set(CHAR(STRING_ELT(phase, 0)));
  return R_NilValue;
}

SEXP log_print(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP names,
  SEXP n_pids
) {
  const char* path_ = CHAR(STRING_ELT(path, 0));
  const int seconds_ = INTEGER(seconds)[0];
  const int nanoseconds_ = INTEGER(nanoseconds)[0];
  const int* pids_ = INTEGER(pids);
  const int n_pids_ = INTEGER(n_pids)[0];
  const char** names_ = (const char**) malloc(n_pids_ * sizeof(char*));
  char phase[PHASE_N];
  if (names_ == NULL) {
    return R_NilValue;
  }
  for (int i = 0; i < n_pids_; ++i) {
    names_[i] = CHAR(STRING_ELT(names, i));
  }
  time_spec_t sleep_spec = time_spec_init(seconds_, nanoseconds_);
  metrics_t* metrics_array = metrics_array_init(n_pids_);
  if (metrics_array == NULL) {
    free(metrics_array);
    return R_NilValue;
  }
  for (int i = 0; i < n_pids_; ++i) {
    metrics_iteration(metrics_array + i, path_, pids_[i]);
  }
  sleep_interval(sleep_spec);
  pthread_phase_get(phase);
  for (int i = 0; i < n_pids_; ++i) {
    metrics_iteration(metrics_array + i, path_, pids_[i]);
    metrics_print(metrics_array + i, path_, pids_[i], names_[i], phase);
  }
  free(names_);
  free(metrics_array);
  return R_NilValue;
}

SEXP log_start(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP names,
  SEXP n_pids
) {
  pthread_args_t* args = pthread_args_init(
    path,
    seconds,
    nanoseconds,
    pids,
    names,
    n_pids
  );
  if (args != NULL) {
    pthread_start(args);
  }
  return R_NilValue;
}

SEXP log_stop(void) {
  pthread_stop();
  return R_NilValue;
}

SEXP log_support(void) {
  return ScalarLogical(1);
}

#else

SEXP log_active(void) {
  return ScalarLogical(0);
}

SEXP log_print(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP n_pids
) {
  return R_NilValue;
}

SEXP log_start(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP n_pids
) {
  return R_NilValue;
}

SEXP log_stop(void) {
  return R_NilValue;
}

SEXP log_support(void) {
  return ScalarLogical(0);
}

#endif

SEXP log_version(void) {
  return Rf_mkString(VERSION);
}
