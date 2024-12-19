#ifndef STAT_H
#define STAT_H

#include <R.h>
#include <Rinternals.h>
#include "support.h"
#include <unistd.h>

#if SUPPORT_NFTW
  #include <errno.h>
  #include <ftw.h>
  #include <string.h>
#endif

typedef struct {
 PROTECT_INDEX index_path;
 PROTECT_INDEX index_size;
 PROTECT_INDEX index_mtime;
 SEXP path;
 SEXP size;
 SEXP mtime;
 int count;
 int capacity;
} nftw_state_t;

SEXP dir_stat(SEXP path);

#endif
