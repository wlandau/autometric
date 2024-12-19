#ifndef THREAD_H
#define THREAD_H

#include "support.h"
#if SUPPORT_LOG

#include "metrics.h"
#include <pthread.h>
#include <R.h>
#include <Rinternals.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "timers.h"
#include <unistd.h>

#define PHASE_DEFAULT "__DEFAULT__"
#define PHASE_N 256

typedef struct {
  char* path;
  int* pids;
  int seconds;
  int nanoseconds;
  char** names;
  int n_pids;
} pthread_args_t;

pthread_args_t* pthread_args_init(
  SEXP path,
  SEXP seconds,
  SEXP nanoseconds,
  SEXP pids,
  SEXP names,
  SEXP n_pids
);

int pthread_run_flag_get(void);
void pthread_phase_get(char* phase);
void pthread_phase_reset(void);
void pthread_phase_set(const char* phase);
void pthread_start(pthread_args_t* args);
void pthread_stop(void);

#endif
#endif
