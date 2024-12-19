#ifndef STAT_H
#define STAT_H

#include <R.h>
#include <Rinternals.h>
#include "support.h"

#if SUPPORT_READDIR
  #include "constant.h"
  #include <dirent.h>
  #include <errno.h>
  #include <sys/stat.h>
  #include <string.h>
#endif

SEXP dir_stat(SEXP path);

#endif
