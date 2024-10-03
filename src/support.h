#ifndef SUPPORT_H
#define SUPPORT_H

#include <time.h>
#include <unistd.h>

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__)
#define WINDOWS 1
#else
#define WINDOWS 0
#endif

#if defined(__APPLE__) && defined(__MACH__)
#define MAC 1
#else
#define MAC 0
#endif

#if defined(__linux__)
#define LINUX 1
#else
#define LINUX 0
#endif

#if defined(WINDOWS) || defined(MAC) || defined(LINUX)
#define SUPPORTED_OS 1
#else
#define SUPPORTED_OS 0
#endif

#if (defined(_POSIX_TIMERS) && (_POSIX_TIMERS > 0)) || MAC
#define TIMERS 1
#else
#define TIMERS 0
#endif

#ifdef _POSIX_THREADS
#define THREADS 1
#else
#define THREADS 0
#endif

#if SUPPORTED_OS && THREADS && (TIMERS || WINDOWS)
#define SUPPORT 1
#else
#define SUPPORT 0
#endif

#endif
