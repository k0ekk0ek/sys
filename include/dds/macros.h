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
#ifndef DDS_ATTRIBUTES_H
#define DDS_ATTRIBUTES_H

#include <stdint.h>

#if defined(__has_attribute)
# define dds_has_attribute(params) __has_attribute(params)
#elif defined(__GNUC__)
# define dds_has_attribute(params) (1) /* GCC < 5 */
#else
# define dds_has_attribute(params) (0)
#endif

#if dds_has_attribute(nonnull)
# define dds_nonnull(params) __attribute__((__nonnull__ params))
# define dds_nonnull_all __attribute__ ((__nonnull__))
#else
# define dds_nonnull(params)
# define dds_nonnull_all
#endif

#if dds_has_attribute(warn_unused_result)
# define dds_warn_unused_result __attribute__ ((__warn_unused_result__))
#else
# define dds_warn_unused_result
#endif

#define DDS_ALIGNAS_1 uint8_t
#define DDS_ALIGNAS_2 uint16_t
#define DDS_ALIGNAS_4 uint32_t
#define DDS_ALIGNAS_8 uint64_t

#define DDS_ALIGNAS_(...) DDS_ALIGNAS_ ## __VA_ARGS__
#define DDS_ALIGNAS(bytes) DDS_ALIGNAS_( bytes )

#endif // DDS_ATTRIBUTES_H
