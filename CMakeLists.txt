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
cmake_minimum_required(VERSION 3.10)
project(sys LANGUAGES C VERSION 0.0.1)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)

include(GenerateExportHeader)

set(include_dir ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(source_dir ${CMAKE_CURRENT_SOURCE_DIR}/src)

set(headers
  ${include_dir}/dds/macros.h
  ${include_dir}/dds/retcode.h)

set(sources)

add_library(sys INTERFACE)
target_include_directories(
  sys INTERFACE
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>")

add_subdirectory(threads)

target_link_libraries(sys INTERFACE sys_threads)

configure_file(include/dds/config.h.in include/dds/config.h)
target_sources(sys INTERFACE ${headers} ${sources})

add_library(dds SHARED)
target_link_libraries(dds PUBLIC sys)
generate_export_header(dds EXPORT_FILE_NAME include/dds/export.h)
