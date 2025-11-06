#include "stat.h"

#if SUPPORT_READDIR

#if OS_MAC
  #define STAT_MTIME st_mtimespec
#else
  #define STAT_MTIME st_mtim
#endif

SEXP dir_stat(SEXP path) {
  const char* parent = CHAR(STRING_ELT(path, 0));
  DIR* handle = opendir(parent);
  if (handle == NULL) {
    Rf_error("opendir() failed on %s: %s", parent, strerror(errno));
  }
  int capacity = BUFFER_SIZE;
  int count = 0;
  int stat_result;
  SEXP file;
  SEXP size;
  SEXP mtime;
  PROTECT_INDEX index_path;
  PROTECT_INDEX index_size;
  PROTECT_INDEX index_mtime;
  PROTECT_WITH_INDEX(file = allocVector(STRSXP, capacity), &index_path);
  PROTECT_WITH_INDEX(size = allocVector(REALSXP, capacity), &index_size);
  PROTECT_WITH_INDEX(mtime = allocVector(REALSXP, capacity), &index_mtime);
  struct dirent *entry;
  struct stat stat_info;
  char buffer[BUFFER_SIZE];
  while ((entry = readdir(handle)) != NULL) {
    R_CheckUserInterrupt();
    snprintf(buffer, BUFFER_SIZE, "%s/%s", parent, entry->d_name);
    if (entry->d_type == DT_REG || entry->d_type == DT_LNK) {
      stat_result = stat(buffer, &stat_info);
    } else {
      continue;
    }
    if (stat_result == -1) {
      continue;
    }
    SET_STRING_ELT(file, count, mkChar(buffer));
    REAL(size)[count] = (double) stat_info.st_size;
    REAL(mtime)[count] = (double) stat_info.STAT_MTIME.tv_sec +
      1e-9 * (double) stat_info.STAT_MTIME.tv_nsec;
    ++count;
    if (count == capacity) {
      capacity *= 2;
      REPROTECT(file = Rf_xlengthgets(file, capacity), index_path);
      REPROTECT(size = Rf_xlengthgets(size, capacity), index_size);
      REPROTECT(mtime = Rf_xlengthgets(mtime, capacity), index_mtime);
    }
  }
  closedir(handle);
  REPROTECT(file = Rf_xlengthgets(file, count), index_path);
  REPROTECT(size = Rf_xlengthgets(size, count), index_size);
  REPROTECT(mtime = Rf_xlengthgets(mtime, count), index_mtime);
  SEXP result = PROTECT(allocVector(VECSXP, 3));
  SEXP names = PROTECT(allocVector(STRSXP, 3));
  SET_STRING_ELT(names, 0, mkChar("path"));
  SET_STRING_ELT(names, 1, mkChar("size"));
  SET_STRING_ELT(names, 2, mkChar("mtime"));
  SET_VECTOR_ELT(result, 0, file);
  SET_VECTOR_ELT(result, 1, size);
  SET_VECTOR_ELT(result, 2, mtime);
  setAttrib(result, R_NamesSymbol, names);
  UNPROTECT(5);
  return result;
}

#else

SEXP dir_stat(SEXP path) {
  return R_NilValue;
}

#endif
