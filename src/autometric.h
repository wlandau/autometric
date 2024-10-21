#ifndef AUTOMETRIC_H
#define AUTOMETRIC_H

#include <R.h>
#include <Rinternals.h>

SEXP log_active(void);
SEXP log_phase_get(void);
SEXP log_phase_set(SEXP phase);
SEXP log_print(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP names,
  SEXP n_pids
);
SEXP log_start(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP names,
  SEXP n_pids
);
SEXP log_stop(void);
SEXP log_support(void);
SEXP log_version(void);

#endif
