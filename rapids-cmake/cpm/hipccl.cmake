# =============================================================================
# cmake-format: off
# SPDX-FileCopyrightText: Copyright (c) 2023-2025, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
# cmake-format: on
# =============================================================================
# MIT License
#
# Modifications Copyright (c) 2025-2026 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#=============================================================================
include_guard(GLOBAL)

#[=======================================================================[.rst:
_rapids_cpm_hipccl_export_package
---------------------------------

Mark the hipCCCL package as a dependency the package associated with the given
export set. This will place a `find_package(hipCCL <version>)` statement
into the config package associated with the given export set.

The global_targets parameter can be used to make imported targets
global targets.

Available targets
^^^^^^^^^^^^^^^^^

  libhipcxx::libhipcxx
  roc::rocthrust
  hip::hipcub
  roc::rocprim_hip
  CCCL::CCCL
  CCCL::Thrust
  CCCL::libcudacxx
  CCCL::CUB
  libcudacxx::libcudacxx
  hipCCL::hipCCL
  hipCCL::hipcub
  hipCCL::rocThrust
  hipCCL::libhipcxx

#]=======================================================================]
function(_rapids_cpm_hipccl_export_package export_type export_set global_targets_list_name version)
  list(APPEND CMAKE_MESSAGE_CONTEXT "export.package")

  include("${rapids-cmake-dir}/export/package.cmake")

  set(extra_args "")
  if(NOT "${version}" STREQUAL "")
    list(APPEND extra_args VERSION ${version})
  endif()
  if(NOT "${${global_targets_list_name}}" STREQUAL "")
    list(APPEND extra_args GLOBAL_TARGETS ${${global_targets_list_name}})
  endif()

  rapids_export_package(${export_type} hipCCL ${export_set} ${extra_args})
endfunction()

#[=======================================================================[.rst
_rapids_cpm_hipccl_create_package
---------------------------------

Creates a hipCCL CMake package whose config
tries to find the packages libhipcxx, rocthrust, rocprim and
hipcub; and provides the below interface targets:

  libhipcxx::libhipcxx
  roc::rocthrust
  hip::hipcub
  roc::rocprim_hip

  CCCL::CCCL
  CCCL::Thrust
  CCCL::libcudacxx
  CCCL::CUB
  libcudacxx::libcudacxx

  hipCCL::hipCCL
  hipCCL::hipcub
  hipCCL::rocThrust
  hipCCL::libhipcxx

.. note::

   Is a macro by design so that all created variables are available to the caller.
#]=======================================================================]
# cmake-lint: disable=R0915
macro(_rapids_cpm_hipccl_create_package version)
  include(${rapids-cmake-dir}/cpm/rocthrust.cmake)
  include(${rapids-cmake-dir}/cpm/libhipcxx.cmake)

  # note: The hipccl package that we generate here defines its own export sets (hipccl-exports) that
  # are separate from the export set(s) that the caller may be using for their own package!
  rapids_cpm_rocthrust(BUILD_EXPORT_SET hipccl-exports INSTALL_EXPORT_SET hipccl-exports ${ARGN})
  rapids_cpm_libhipcxx(BUILD_EXPORT_SET hipccl-exports INSTALL_EXPORT_SET hipccl-exports ${ARGN})

  # TODO(HIP/AMD): it would be good to configure hipcub with rapids-cmake, too.
  #
  # note: CMake only permits promoting an imported target to global scope from the directory that
  # created it, so the `GLOBAL_TARGETS` of the generated hipccl package have to be promoted here.
  include("${rapids-cmake-dir}/find/package.cmake")
  rapids_find_package(rocprim REQUIRED GLOBAL_TARGETS roc::rocprim_hip)
  rapids_find_package(hipcub REQUIRED GLOBAL_TARGETS hip::hipcub)

  # libcudacxx
  add_library(libcudacxx_libcudacxx INTERFACE)
  target_link_libraries(libcudacxx_libcudacxx INTERFACE libhipcxx::libhipcxx)

  add_library(CCCL_libcudacxx INTERFACE)
  target_link_libraries(CCCL_libcudacxx INTERFACE libcudacxx_libcudacxx)
  add_library(hipCCL_libhipcxx INTERFACE)
  target_link_libraries(hipCCL_libhipcxx INTERFACE CCCL_libcudacxx)

  # Thrust
  add_library(CCCL_Thrust INTERFACE)
  target_link_libraries(CCCL_Thrust INTERFACE roc::rocthrust)
  add_library(hipCCL_rocThrust INTERFACE)
  target_link_libraries(hipCCL_rocThrust INTERFACE CCCL_Thrust)

  # CUB
  add_library(CCCL_CUB INTERFACE)
  target_link_libraries(CCCL_CUB INTERFACE hip::hipcub)
  add_library(hipCCL_hipcub INTERFACE)
  target_link_libraries(hipCCL_hipcub INTERFACE CCCL_CUB)

  # CCCL
  add_library(CCCL_CCCL INTERFACE)
  target_link_libraries(CCCL_CCCL INTERFACE hipCCL_hipcub hipCCL_rocThrust hipCCL_libhipcxx)

  # hipCCL
  add_library(hipCCL_hipCCL INTERFACE)
  target_link_libraries(hipCCL_hipCCL INTERFACE CCCL_CCCL)

  # configure export names
  set_target_properties(CCCL_CCCL PROPERTIES EXPORT_NAME CCCL::CCCL)
  set_target_properties(CCCL_Thrust PROPERTIES EXPORT_NAME CCCL::Thrust)
  set_target_properties(CCCL_libcudacxx PROPERTIES EXPORT_NAME CCCL::libcudacxx)
  set_target_properties(CCCL_CUB PROPERTIES EXPORT_NAME CCCL::CUB)
  set_target_properties(libcudacxx_libcudacxx PROPERTIES EXPORT_NAME libcudacxx::libcudacxx)
  set_target_properties(hipCCL_hipCCL PROPERTIES EXPORT_NAME hipCCL::hipCCL)
  set_target_properties(hipCCL_hipcub PROPERTIES EXPORT_NAME hipCCL::hipcub)
  set_target_properties(hipCCL_rocThrust PROPERTIES EXPORT_NAME hipCCL::rocThrust)
  set_target_properties(hipCCL_libhipcxx PROPERTIES EXPORT_NAME hipCCL::libhipcxx)

  # provide ALIAS targets to caller
  add_library(CCCL::CCCL ALIAS CCCL_CCCL)
  add_library(CCCL::Thrust ALIAS CCCL_Thrust)
  add_library(CCCL::libcudacxx ALIAS CCCL_libcudacxx)
  add_library(CCCL::CUB ALIAS CCCL_CUB)
  add_library(libcudacxx::libcudacxx ALIAS libcudacxx_libcudacxx)
  add_library(hipCCL::hipCCL ALIAS hipCCL_hipCCL)
  add_library(hipCCL::hipcub ALIAS hipCCL_hipcub)
  add_library(hipCCL::rocThrust ALIAS hipCCL_rocThrust)
  add_library(hipCCL::libhipcxx ALIAS hipCCL_libhipcxx)

  include("${rapids-cmake-dir}/export/package.cmake")
  foreach(export_type BUILD INSTALL)
    # add find_package / find_dependency to hipccl-dependencies.cmake file
    rapids_export_package(${export_type} rocprim hipccl-exports VERSION ${rocprim_VERSION}
                          GLOBAL_TARGETS roc::rocprim_hip)
    rapids_export_package(${export_type} libhipcxx hipccl-exports VERSION ${libhipcxx_VERSION}
                          GLOBAL_TARGETS libhipcxx::libhipcxx)
    rapids_export_package(${export_type} hipcub hipccl-exports VERSION ${hipcub_VERSION}
                          GLOBAL_TARGETS hip::hipcub)
    rapids_export_package(${export_type} rocthrust hipccl-exports VERSION ${rocthrust_VERSION})
  endforeach()

  set(base_targets libhipcxx::libhipcxx roc::rocthrust hip::hipcub roc::rocprim_hip)

  set(cccl_targets_to_export CCCL_CCCL CCCL_Thrust CCCL_libcudacxx CCCL_CUB libcudacxx_libcudacxx)

  set(hipccl_targets hipCCL_hipCCL hipCCL_hipcub hipCCL_rocThrust hipCCL_libhipcxx)

  rapids_cmake_install_lib_dir(lib_dir)
  # NOTE: Not all commands accept generator expressions
  install(TARGETS ${cccl_targets_to_export} ${hipccl_targets} DESTINATION ${lib_dir}
          EXPORT hipccl-exports)
  include("${rapids-cmake-dir}/export/export.cmake")
  foreach(export_type BUILD INSTALL)
    rapids_export(${export_type} "hipCCL" EXPORT_SET "hipccl-exports"
                  GLOBAL_TARGETS ${base_targets} ${cccl_targets_to_export} ${hipccl_targets}
                  VERSION ${version})
  endforeach()
endmacro()

#[=======================================================================[.rst:
rapids_cpm_hipccl
-----------------

.. versionadded:: v25.02.00

Allow projects to find or build `CCCL`-associated libraries via `CPM` with built-in
tracking of these dependencies for correct export support.

.. code-block:: cmake

  rapids_cpm_hipccl( [BUILD_EXPORT_SET <export-name>]
                   [INSTALL_EXPORT_SET <export-name>]
                   [<CPM_ARGS> ...])

.. include:: common_package_args.txt

Result Targets
^^^^^^^^^^^^^^
  CCCL::CCCL target will be created
  CCCL::Thrust target will be created
  CCCL::libcudacxx target will be created
  CCCL::CUB target will be created

  libcudacxx_libcudacxx target will be created

  hipCCL::hipCCL target will be created
  hipCCL::rocThrust target will be created
  hipCCL::libhipcxx target will be created
  hipCCL::hipcub target will be created

  libhipcxx::libhipcxx target might be created if it doesn't exists
  roc::rocThrust target might be created if it doesn't exists
  hip::hipcub target might be created if it doesn't exists
  roc::rocprim target might be created if it doesn't exists

Result Variables
^^^^^^^^^^^^^^^^

  :cmake:variable:`hipCCL_ADDED` is set to a true value if hipCCL has not been added before.
  :cmake:variable:`hipCCL_VERSION` is set to the version of CCCL(!) specified by the versions.json
  :cmake:variable:`CCCL_ADDED`   Same as ``hipCCL_``-prefixed variable (only available if HIP_AS_CUDA option is set).
  :cmake:variable:`CCCL_VERSION` Same as ``hipCCL_``-prefixed variable (only available if HIP_AS_CUDA option is set).

  :cmake:variable:`<dependency>_SOURCE_DIR` For each dependency 'CUB'/'hipcub','libcudacxx'/'libhipcxx','Thrust'/'rocthrust' and 'rocprim', set to the path to the source directory of the dependency.
  :cmake:variable:`<dependency>_BINARY_DIR` For each dependency 'CUB'/'hipcub','libcudacxx'/'libhipcxx','Thrust'/'rocthrust' and 'rocprim', set to the path to the build directory of the dependency.
  :cmake:variable:`<dependency>_ADDED`      For each dependency 'CUB'/'hipcub','libcudacxx'/'libhipcxx','Thrust'/'rocthrust' and 'rocprim', set to a true value if the dependency has not been added before.
  :cmake:variable:`<dependency>_VERSION`    For each dependency 'CUB'/'hipcub','libcudacxx'/'libhipcxx','Thrust'/'rocthrust' and 'rocprim', set to the version of the dependency.

#]=======================================================================]
# cmake-lint: disable=R0915
function(rapids_cpm_hipccl)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.hipccl")
  set(options ENABLE_UNSTABLE)
  set(one_value BUILD_EXPORT_SET INSTALL_EXPORT_SET)
  set(multi_value "")
  # TODO handle GLOBAL_TARGETS
  cmake_parse_arguments(_RAPIDS "${options}" "${one_value}" "${multi_value}" "${ARGN}")

  # NOTE(HIP/AMD): ENABLE_UNSTABLE accepted for API parity with upstream rapids_cpm_cccl
  # (added in upstream commit 9107d20). On the CUDA backend this enables CCCL_ENABLE_UNSTABLE
  # to expose the CCCL::cudax target. There is no HIP equivalent of CCCL's experimental
  # `cudax` library, so the flag is a no-op on the HIP backend.
  if(_RAPIDS_ENABLE_UNSTABLE)
    message(WARNING "rapids_cpm_hipccl: ENABLE_UNSTABLE accepted for API parity but is a no-op on HIP backend (no CCCL::cudax equivalent)")
  endif()

  # note: store as the variables are affected by side effects
  set(build_export_set ${_RAPIDS_BUILD_EXPORT_SET})
  set(install_export_set ${_RAPIDS_INSTALL_EXPORT_SET})

  # Get CCCL package info TODO handle cccl_shallow?
  include("${rapids-cmake-dir}/cpm/detail/package_info.cmake")

  # NOTE: (1/2) backup value of variables that may be modified as side effect when calling
  # 'rapids_cpm_package_details'
  set(CPM_DOWNLOAD_ALL_BACKUP ${CPM_DOWNLOAD_ALL})
  set(rapids_cmake_always_download_backup ${rapids_cmake_always_download})

  rapids_cpm_package_info(CCCL ${_RAPIDS_UNPARSED_ARGUMENTS} VERSION_VAR cccl_version FIND_VAR
                          find_args CPM_VAR cpm_find_info TO_INSTALL_VAR to_install)

  # NOTE: (2/2) restore original variable values
  set(CPM_DOWNLOAD_ALL ${CPM_DOWNLOAD_ALL_BACKUP})
  set(rapids_cmake_always_download ${rapids_cmake_always_download_backup})

  set(global_targets_list
      libhipcxx::libhipcxx roc::rocthrust hip::hipcub roc::rocprim_hip CCCL::CCCL CCCL::Thrust
      CCCL::libcudacxx CCCL::CUB libcudacxx::libcudacxx hipCCL::hipCCL hipCCL::hipcub
      hipCCL::rocThrust hipCCL::libhipcxx)

  # Add find_package(hipccl) / find_dependency(hipccl) to <caller>-dependencies.cmake file
  # associated with ${(INSTALL|BUILD)_EXPORT_SET}
  foreach(export_type BUILD INSTALL)
    string(TOLOWER ${export_type} export_type_lower)
    if(${export_type_lower}_export_set)
      _rapids_cpm_hipccl_export_package(${export_type} ${${export_type_lower}_export_set}
                                        global_targets_list ${cccl_version})
    endif()
  endforeach()

  # Resolve CPM policy variables (each can be set as a CMake variable or environment variable).
  # CPM_DOWNLOAD_ALL: skip find_package, always create the package from source.
  # CPM_LOCAL_PACKAGES_ONLY: only use find_package, error if not found.
  # CPM_USE_LOCAL_PACKAGES: try find_package first (default behavior here).
  set(_hipccl_download_all OFF)
  if(CPM_DOWNLOAD_ALL OR rapids_cmake_always_download)
    set(_hipccl_download_all ON)
  elseif(DEFINED ENV{CPM_DOWNLOAD_ALL} AND "$ENV{CPM_DOWNLOAD_ALL}")
    set(_hipccl_download_all ON)
  endif()

  set(_hipccl_local_packages_only OFF)
  if(CPM_LOCAL_PACKAGES_ONLY)
    set(_hipccl_local_packages_only ON)
  elseif(DEFINED ENV{CPM_LOCAL_PACKAGES_ONLY} AND "$ENV{CPM_LOCAL_PACKAGES_ONLY}")
    set(_hipccl_local_packages_only ON)
  endif()

  if(_hipccl_download_all AND NOT _hipccl_local_packages_only)
    message(STATUS "CPM_DOWNLOAD_ALL is set -- skipping find_package(hipCCL) and creating package from source")
    _rapids_cpm_hipccl_create_package(${cccl_version} ${_RAPIDS_UNPARSED_ARGUMENTS})
  else()
    find_package(hipCCL ${cccl_version} QUIET)
    if(TARGET hipCCL::hipCCL)
      message(STATUS "Found preinstalled hipCCL CMake package")
    elseif(_hipccl_local_packages_only)
      message(FATAL_ERROR "CPM_LOCAL_PACKAGES_ONLY is set but find_package(hipCCL ${cccl_version}) "
                          "did not find a local installation. Install hipCCL or unset CPM_LOCAL_PACKAGES_ONLY.")
    else()
      message(STATUS "Create hipCCL CMake package and ALIAS targets")
      _rapids_cpm_hipccl_create_package(${cccl_version} ${_RAPIDS_UNPARSED_ARGUMENTS})
    endif()
  endif()

  # Propagate CCCL related variables to parent scope
  set(hipCCL_ADDED ON PARENT_SCOPE)
  set(CCCL_ADDED ON PARENT_SCOPE)
  set(hipCCL_VERSION "${cccl_version}" PARENT_SCOPE)
  set(CCCL_VERSION "${cccl_version}" PARENT_SCOPE)

  # Propagate up variables that CPMFindPackage provides
  set(libhipcxx_SOURCE_DIR "${libhipcxx_SOURCE_DIR}" PARENT_SCOPE)
  set(libhipcxx_BINARY_DIR "${libhipcxx_BINARY_DIR}" PARENT_SCOPE)
  set(libhipcxx_ADDED "${libhipcxx_ADDED}" PARENT_SCOPE)
  set(libhipcxx_VERSION "${libhipcxx_VERSION}" PARENT_SCOPE)

  set(rocthrust_SOURCE_DIR "${rocthrust_SOURCE_DIR}" PARENT_SCOPE)
  set(rocthrust_BINARY_DIR "${rocthrust_BINARY_DIR}" PARENT_SCOPE)
  set(rocthrust_ADDED "${rocthrust_ADDED}" PARENT_SCOPE)
  set(rocthrust_VERSION "${rocthrust_VERSION}" PARENT_SCOPE)

  set(hipcub_SOURCE_DIR "${hipcub_SOURCE_DIR}" PARENT_SCOPE)
  set(hipcub_BINARY_DIR "${hipcub_BINARY_DIR}" PARENT_SCOPE)
  set(hipcub_ADDED "${hipcub_ADDED}" PARENT_SCOPE)
  set(hipcub_VERSION "${hipcub_VERSION}" PARENT_SCOPE)

  set(rocprim_SOURCE_DIR "${rocprim_SOURCE_DIR}" PARENT_SCOPE)
  set(rocprim_BINARY_DIR "${rocprim_BINARY_DIR}" PARENT_SCOPE)
  set(rocprim_ADDED "${rocprim_ADDED}" PARENT_SCOPE)
  set(rocprim_VERSION "${rocprim_VERSION}" PARENT_SCOPE)

  if(HIP_AS_CUDA)
    set(libcudacxx_SOURCE_DIR "${libhipcxx_SOURCE_DIR}" PARENT_SCOPE)
    set(libcudacxx_BINARY_DIR "${libhipcxx_BINARY_DIR}" PARENT_SCOPE)
    set(libcudacxx_ADDED "${libhipcxx_ADDED}" PARENT_SCOPE)
    set(libcudacxx_VERSION "${libhipcxx_VERSION}" PARENT_SCOPE)

    set(Thrust_SOURCE_DIR "${rocthrust_SOURCE_DIR}" PARENT_SCOPE)
    set(Thrust_BINARY_DIR "${rocthrust_BINARY_DIR}" PARENT_SCOPE)
    set(Thrust_ADDED "${rocthrust_ADDED}" PARENT_SCOPE)
    set(Thrust_VERSION "${rocthrust_VERSION}" PARENT_SCOPE)

    set(CUB_SOURCE_DIR "${hipcub_SOURCE_DIR}" PARENT_SCOPE)
    set(CUB_BINARY_DIR "${hipcub_BINARY_DIR}" PARENT_SCOPE)
    set(CUB_ADDED "${hipcub_ADDED}" PARENT_SCOPE)
    set(CUB_VERSION "${hipcub_VERSION}" PARENT_SCOPE)
  endif()

endfunction()

if(HIP_AS_CUDA)
  #[=======================================================================[.rst:
  rapids_cpm_cccl
  ---------------------------------

  Simply delegates to `rapids_cpm_hipccl`.
  #]=======================================================================]
  macro(rapids_cpm_cccl)
    rapids_cpm_hipccl(${ARGN})
  endmacro()
endif()

