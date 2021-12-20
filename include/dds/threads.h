/*
 * Copyright(c) 2021 ADLINK Technology Limited and others
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0, or the Eclipse Distribution License
 * v. 1.0 which is available at
 * http://www.eclipse.org/org/documents/edl-v10.php.
 *
 * SPDX-License-Identifier: EPL-2.0 OR BSD-3-Clause
 */
#ifndef DDS_THREADS_H
#define DDS_THREADS_H

#include <stdbool.h>
#include <stdint.h>
#include <inttypes.h>

#include "dds/export.h"
#include "dds/config.h"
#include "dds/macros.h"
#include "dds/retcode.h"

#if defined(__cplusplus)
extern "C" {
#endif

#if defined(_MSC_VER) || __MINGW__
# define dds_thread_local __declspec(thread)
#elif defined(__GNUC__) || (defined(__clang__) && __clang_major__ >= 2)
  /* GCC supports Thread-local storage for x86 since version 3.3. Clang
     supports Thread-local storage since version 2.0. */
# define dds_thread_local __thread
#endif

typedef union
{
  char __size[DDS_SIZEOF_THRD_T];
  DDS_ALIGNAS(DDS_ALIGNOF_THRD_T) __align;
} dds_thrd_t;

#if _WIN32
  typedef uint32_t dds_tid_t;
  #define DDS_TIDF PRIu32
#else
  #if defined(__linux)
    typedef long int dds_tid_t;
    #define DDS_TIDF "ld"
  #elif defined(__FreeBSD__) && (__FreeBSD__ >= 9)
    typedef int dds_tid_t;
    #define DDS_TIDF "d"
  #endif
#endif

DDS_EXPORT dds_return_t
dds_thrd_create(
  dds_thrd_t *thr,
  const char *name,
  dds_thrdattr_t *attr,
  dds_thrd_start_t *start,
  void *arg)
dds_nonnull((1,3,4));

DDS_EXPORT dds_return_t
dds_thrd_join(
  dds_thrd_t thr,
  uint32_t *res);

typedef union
{
  char __size[DDS_SIZEOF_MTX_T];
  DDS_ALIGNAS(DDS_ALIGNOF_MTX_T) __align;
} dds_mtx_t;

DDS_EXPORT void dds_mtx_init(dds_mtx_t *)
  dds_nonnull_all;

DDS_EXPORT void dds_mtx_lock(dds_mtx_t *)
  dds_nonnull_all;

DDS_EXPORT bool dds_mtx_trylock(dds_mtx_t *)
  dds_nonnull_all
  dds_warn_unused_result;

DDS_EXPORT void dds_mtx_unlock(dds_mtx_t *)
  dds_nonnull_all;

#if defined(__cplusplus)
}
#endif

#endif // DDS_THREADS_H
