#ifndef SUPPORT_H
#define SUPPORT_H

#include <time.h>
#include <unistd.h>

#ifndef OS_WINDOWS
  #if defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || \
    defined(__NT__)
    #define OS_WINDOWS 1
  #else
    #define OS_WINDOWS 0
  #endif
#endif

#ifndef OS_MAC
  #if defined(__APPLE__) && defined(__MACH__)
    #define OS_MAC 1
  #else
    #define OS_MAC 0
  #endif
#endif

#ifndef OS_LINUX
  #if defined(__linux__)
    #define OS_LINUX 1
  #else
    #define OS_LINUX 0
  #endif
#endif

#ifndef SUPPORT_OS
  #if defined(OS_WINDOWS) || defined(OS_MAC) || defined(OS_LINUX)
    #define SUPPORT_OS 1
  #else
    #define SUPPORT_OS 0
  #endif
#endif

#ifndef SUPPORT_TIMERS
  #if (defined(_POSIX_TIMERS) && (_POSIX_TIMERS > 0)) || OS_MAC
    #define SUPPORT_TIMERS 1
  #else
    #define SUPPORT_TIMERS 0
  #endif
#endif

#ifndef SUPPORT_THREADS
  #ifdef _POSIX_THREADS
    #define SUPPORT_THREADS 1
  #else
    #define SUPPORT_THREADS 0
  #endif
#endif

#ifndef SUPPORT_LOG
  #if SUPPORT_OS && SUPPORT_THREADS && (SUPPORT_TIMERS || OS_WINDOWS)
    #define SUPPORT_LOG 1
  #else
    #define SUPPORT_LOG 0
  #endif
#endif

#ifndef SUPPORT_READDIR
  #define SUPPORT_READDIR 0
  #ifdef _POSIX_VERSION
    #if _POSIX_C_SOURCE >= 200809L || OS_MAC
      #undef SUPPORT_READDIR
      #define SUPPORT_READDIR 1
      #define _XOPEN_SOURCE 600
    #endif
  #endif
#endif

#endif
