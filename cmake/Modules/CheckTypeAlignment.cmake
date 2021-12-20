# Modified version of CheckTypeSize.cmake distributed with CMake.
# Copyright 2000-2021 Kitware, Inc. and Contributors

#
# Copyright(c) 2021 ADLINK Technology Limited and others
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v. 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0, or the Eclipse Distribution License
# v. 1.0 which is available at
# http://www.eclipse.org/org/documents/edl-v10.php.
#
# SPDX-License-Identifier: BSD-3-Clause
#

function(__check_type_alignment_impl type var map builtin language)
  if(NOT CMAKE_REQUIRED_QUIET)
    message(CHECK_START "Check alignment of ${type}")
  endif()

  # Perform language check
  if(language STREQUAL "C")
    set(src ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CheckTypeAlignment/${var}.c)
  elseif(language STREQUAL "CXX")
    set(src ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CheckTypeAlignment/${var}.cpp)
  else()
    message(FATAL_ERROR "Unknown language:\n  ${language}\nSupported languages: C, CXX.\n")
  endif()

  # Include header files.
  set(headers)
  if(builtin)
    if(language STREQUAL "CXX" AND type MATCHES "^std::")
      if(HAVE_SYS_TYPES_H)
        string(APPEND headers "#include <sys/types.h>\n")
      endif()
      if(HAVE_CSTDINT)
        string(APPEND headers "#include <cstdint>\n")
      endif()
      if(HAVE_CSTDDEF)
        string(APPEND headers "#include <cstddef>\n")
      endif()
    else()
      if(HAVE_SYS_TYPES_H)
        string(APPEND headers "#include <sys/types.h>\n")
      endif()
      if(HAVE_STDINT_H)
        string(APPEND headers "#include <stdint.h>\n")
      endif()
      if(HAVE_STDDEF_H)
        string(APPEND headers "#include <stddef.h>\n")
      endif()
    endif()
  endif()
  foreach(h ${CMAKE_EXTRA_INCLUDE_FILES})
    string(APPEND headers "#include \"${h}\"\n")
  endforeach()

  # Perform the check.
  set(bin ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CheckTypeAlignment/${var}.bin)
  configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CheckTypeAlignment.c.in ${src} @ONLY)
  try_compile(HAVE_${var} ${CMAKE_BINARY_DIR} ${src}
    COMPILE_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS}
    LINK_OPTIONS ${CMAKE_REQUIRED_LINK_OPTIONS}
    LINK_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES}
    CMAKE_FLAGS
      "-DCOMPILE_DEFINITIONS:STRING=${CMAKE_REQUIRED_FLAGS}"
      "-DINCLUDE_DIRECTORIES:STRING=${CMAKE_REQUIRED_INCLUDES}"
    OUTPUT_VARIABLE output
    COPY_FILE ${bin}
    )

  if(HAVE_${var})
    # The check compiled.  Load information from the binary.
    file(STRINGS ${bin} strings LIMIT_COUNT 10 REGEX "INFO:alignment")

    # Parse the information strings.
    set(regex_align ".*INFO:alignment\\[0*([^]]*)\\].*")
    set(regex_key " key\\[([^]]*)\\]")
    set(keys)
    set(code)
    set(mismatch)
    set(first 1)
    foreach(info ${strings})
      if("${info}" MATCHES "${regex_align}")
        # Get the type alignment.
        set(alignment "${CMAKE_MATCH_1}")
        if(first)
          set(${var} ${alignment})
        elseif(NOT "${alignment}" STREQUAL "${${var}}")
          set(mismatch 1)
        endif()
        set(first 0)

        # Get the architecture map key.
        string(REGEX MATCH   "${regex_key}"       key "${info}")
        string(REGEX REPLACE "${regex_key}" "\\1" key "${key}")
        if(key)
          string(APPEND code "\nset(${var}-${key} \"${alignment}\")")
          list(APPEND keys ${key})
        endif()
      endif()
    endforeach()

    # Update the architecture-to-alignment map.
    if(mismatch AND keys)
      configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CheckTypeAlignmentMap.cmake.in ${map} @ONLY)
      set(${var} 0)
    else()
      file(REMOVE ${map})
    endif()

    if(mismatch AND NOT keys)
      message(SEND_ERROR "CHECK_TYPE_ALIGNMENT found different results, consider setting CMAKE_OSX_ARCHITECTURES or CMAKE_TRY_COMPILE_OSX_ARCHITECTURES to one or no architecture !")
    endif()

    if(NOT CMAKE_REQUIRED_QUIET)
      message(CHECK_PASS "done")
    endif()
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
      "Determining alignment of ${type} passed with the following output:\n${output}\n\n")
    set(${var} "${${var}}" CACHE INTERNAL "CHECK_TYPE_ALIGNMENT: alignof(${type})")
  else()
    # The check failed to compile.
    if(NOT CMAKE_REQUIRED_QUIET)
      message(CHECK_FAIL "failed")
    endif()
    file(READ ${src} content)
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Determining alignment of ${type} failed with the following output:\n${output}\n${src}:\n${content}\n\n")
    set(${var} "" CACHE INTERNAL "CHECK_TYPE_ALIGNMENT: ${type} unknown")
    set(${var}_TYPE "" CACHE INTERNAL "CHECK_TYPE_ALIGNMENT: ${type} unknown")
    file(REMOVE ${map})
  endif()
endfunction()

macro(CHECK_TYPE_ALIGNMENT TYPE VARIABLE)
  # parse arguments
  unset(doing)
  foreach(arg ${ARGN})
    if("x${arg}" STREQUAL "xBUILTIN_TYPES_ONLY")
      set(_CHECK_TYPE_ALIGNMENT_${arg} 1)
      unset(doing)
    elseif("x${arg}" STREQUAL "xTYPE_SPECIFIER")
      set(_CHECK_TYPE_ALIGNMENT_${arg} 1)
      unset(doing)
    elseif("x${arg}" STREQUAL "xLANGUAGE") # change to MATCHES for more keys
      set(doing "${arg}")
      set(_CHECK_TYPE_ALIGNMENT_${doing} "")
    elseif("x${doing}" STREQUAL "xLANGUAGE")
      set(_CHECK_TYPE_ALIGNMENT_${doing} "${arg}")
      unset(doing)
    else()
      message(FATAL_ERROR "Unknown argument:\n  ${arg}\n")
    endif()
  endforeach()
  if("x${doing}" MATCHES "^x(LANGUAGE)$")
    message(FATAL_ERROR "Missing argument:\n  ${doing} arguments requires a value\n")
  endif()
  if(DEFINED _CHECK_TYPE_ALIGNMENT_LANGUAGE)
    if(NOT "x${_CHECK_TYPE_ALIGNMENT_LANGUAGE}" MATCHES "^x(C|CXX)$")
      message(FATAL_ERROR "Unknown language:\n  ${_CHECK_TYPE_ALIGNMENT_LANGUAGE}.\nSupported languages: C, CXX.\n")
    endif()
    set(_language ${_CHECK_TYPE_ALIGNMENT_LANGUAGE})
  else()
    set(_language C)
  endif()

  # Optionally check for standard headers.
  if(_CHECK_TYPE_ALIGNMENT_BUILTIN_TYPES_ONLY)
    set(_builtin 0)
  else()
    set(_builtin 1)
    if(_language STREQUAL "C")
      check_include_file(sys/types.h HAVE_SYS_TYPES_H)
      check_include_file(stdint.h HAVE_STDINT_H)
      check_include_file(stddef.h HAVE_STDDEF_H)
    elseif(_language STREQUAL "CXX")
      check_include_file_cxx(sys/types.h HAVE_SYS_TYPES_H)
      if("${TYPE}" MATCHES "^std::")
        check_include_file_cxx(cstdint HAVE_CSTDINT)
        check_include_file_cxx(cstddef HAVE_CSTDDEF)
      else()
        check_include_file_cxx(stdint.h HAVE_STDINT_H)
        check_include_file_cxx(stddef.h HAVE_STDDEF_H)
      endif()
    endif()
  endif()
  unset(_CHECK_TYPE_ALIGNMENT_BUILTIN_TYPES_ONLY)
  unset(_CHECK_TYPE_ALIGNMENT_LANGUAGE)

  # Compute or load the size or size map.
  set(${VARIABLE}_KEYS)
  set(_map_file ${CMAKE_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CheckTypeAlignment/${VARIABLE}.cmake)
  if(NOT DEFINED HAVE_${VARIABLE})
    __check_type_alignment_impl(${TYPE} ${VARIABLE} ${_map_file} ${_builtin} ${_language})
  endif()
  include(${_map_file} OPTIONAL)
  set(_map_file)
  set(_builtin)

  # Create preprocessor code.
  if(${VARIABLE}_KEYS)
    set(${VARIABLE}_CODE)
    set(_if if)
    foreach(key ${${VARIABLE}_KEYS})
      string(APPEND ${VARIABLE}_CODE "#${_if} defined(${key})\n# define ${VARIABLE} ${${VARIABLE}-${key}}\n")
      set(_if elif)
    endforeach()
    string(APPEND ${VARIABLE}_CODE "#else\n# error ${VARIABLE} unknown\n#endif")
    set(_if)
  elseif(${VARIABLE})
    set(${VARIABLE}_CODE "#define ${VARIABLE} ${${VARIABLE}}")
  else()
    set(${VARIABLE}_CODE "/* #undef ${VARIABLE} */")
  endif()
endmacro()
