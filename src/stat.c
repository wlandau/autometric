#include "stat.h"

#if SUPPORT_NFTW

int nftw_entry(
  const char *fpath,
  const struct stat *sb,
  int typeflag,
  struct FTW *ftwbuf
) {
  R_CheckUserInterrupt();
  if (typeflag == FTW_F) {
    if (state.count == state.capacity) {
      state.capacity *= 2;
      REPROTECT(
        state.path = Rf_xlengthgets(state.path, state.capacity),
        state.index_path
      );
      REPROTECT(
        state.size = Rf_xlengthgets(state.size, state.capacity),
        state.index_size
      );
      REPROTECT(
        state.mtime = Rf_xlengthgets(state.mtime, state.capacity),
        state.index_mtime
      );
    }
    SET_STRING_ELT(state.path, state.count, mkChar(fpath));
    REAL(state.size)[state.count] = (double) sb->st_size;
    REAL(state.mtime)[state.count] = (double) sb->st_mtime;
    state.count++;
  }
  return 0;
}

SEXP dir_stat(SEXP path) {
  state.count = 0;
  state.capacity = 2048;
  PROTECT_WITH_INDEX(
    state.path = allocVector(STRSXP, state.capacity),
    &state.index_path
  );
  PROTECT_WITH_INDEX(
    state.size = allocVector(REALSXP, state.capacity),
    &state.index_size
  );
  PROTECT_WITH_INDEX(
    state.mtime = allocVector(REALSXP, state.capacity),
    &state.index_mtime
  );
  if (nftw(CHAR(STRING_ELT(path, 0)), nftw_entry, 20, FTW_PHYS) == -1) {
    Rf_error("nftw() failed: %s", strerror(errno));
  }
  REPROTECT(
    state.path = Rf_xlengthgets(state.path, state.count),
    state.index_path
  );
  REPROTECT(
    state.size = Rf_xlengthgets(state.size, state.count),
    state.index_size
  );
  REPROTECT(
    state.mtime = Rf_xlengthgets(state.mtime, state.count),
    state.index_mtime
  );
  SEXP result = PROTECT(allocVector(VECSXP, 3));
  SEXP names = PROTECT(allocVector(STRSXP, 3));
  SET_STRING_ELT(names, 0, mkChar("path"));
  SET_STRING_ELT(names, 1, mkChar("size"));
  SET_STRING_ELT(names, 2, mkChar("mtime"));
  SET_VECTOR_ELT(result, 0, state.path);
  SET_VECTOR_ELT(result, 1, state.size);
  SET_VECTOR_ELT(result, 2, state.mtime);
  setAttrib(result, R_NamesSymbol, names);
  state.path = R_NilValue;
  state.size = R_NilValue;
  state.mtime = R_NilValue;
  UNPROTECT(5);
  return result;
}

#else

#include <stdio.h>

SEXP dir_stat(SEXP path) {
  Rprintf("unsupported: %ld\n", _POSIX_VERSION);
  return R_NilValue;
}

#endif
