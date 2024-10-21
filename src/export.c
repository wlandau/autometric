#include "autometric.h"

static const R_CallMethodDef call_methods[] = {
  {"r_log_active", (DL_FUNC) &log_active, 0},
  {"r_log_phase_get", (DL_FUNC) &log_phase_get, 0},
  {"r_log_phase_set", (DL_FUNC) &log_phase_set, 1},
  {"r_log_print", (DL_FUNC) &log_print, 6},
  {"r_log_start", (DL_FUNC) &log_start, 6},
  {"r_log_stop", (DL_FUNC) &log_stop, 0},
  {"r_log_support", (DL_FUNC) &log_support, 0},
  {"r_log_version", (DL_FUNC) &log_version, 0},
  {NULL, NULL, 0}
};

void R_init_autometric(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
