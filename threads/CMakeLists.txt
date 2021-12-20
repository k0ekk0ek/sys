#
# Copyright(c) 2021 ADLINK Technology Limited and others
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v. 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0, or the Eclipse Distribution License
# v. 1.0 which is available at
# http://www.eclipse.org/org/documents/edl-v10.php.
#
# SPDX-License-Identifier: EPL-2.0 OR BSD-3-Clause
#
include(CheckTypeSize)
include(CheckTypeAlignment)

find_package(Threads REQUIRED)

add_library(sys_threads INTERFACE)
target_link_libraries(sys_threads INTERFACE Threads::Threads)
if(WIN32)
  set(CMAKE_EXTRA_INCLUDE_FILES ${CMAKE_CURRENT_SOURCE_DIR}/windows/threads.h)
  set(sources ${CMAKE_CURRENT_SOURCE_DIR}/windows/threads.c)
else()
  set(CMAKE_EXTRA_INCLUDE_FILES ${CMAKE_CURRENT_SOURCE_DIR}/posix/threads.h)
  set(sources ${CMAKE_CURRENT_SOURCE_DIR}/posix/threads.c)
endif()

set(CMAKE_REQUIRED_QUIET TRUE)

check_type_size("struct dds_thrd" DDS_SIZEOF_THRD_T)
check_type_alignment("struct dds_thrd" DDS_ALIGNOF_THRD_T)
check_type_size("struct dds_mtx" DDS_SIZEOF_MTX_T)
check_type_alignment("struct dds_mtx" DDS_ALIGNOF_MTX_T)

unset(CMAKE_REQUIRED_QUIET)
unset(CMAKE_EXTRA_INCLUDE_FILES)

target_sources(sys_threads INTERFACE ${sources})
