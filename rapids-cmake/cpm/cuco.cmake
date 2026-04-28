# =============================================================================
# cmake-format: off
# SPDX-FileCopyrightText: Copyright (c) 2022-2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
# cmake-format: on
# =============================================================================
# MIT License
#
# Modifications Copyright (c) 2023-2026 Advanced Micro Devices, Inc.
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
# =============================================================================
include_guard(GLOBAL)

# <<<<<<< OLD CODE from 0e74b344 (5a62d8b0) - COMMENTED OUT
# option(CUDA_BACKEND "If the CUDA_BACKEND should be used. Defaults to OFF." OFF)
# =======
#[=======================================================================[.rst:
rapids_cpm_cuco
---------------------

.. versionadded:: v22.08.00

Allow projects to find or build `cuCollections` via `CPM` with built-in
tracking of these dependencies for correct export support.

Uses the version of cuCollections :ref:`specified in the version file <cpm_versions>` for consistency
across all RAPIDS projects.

.. code-block:: cmake

  rapids_cpm_cuco( [BUILD_EXPORT_SET <export-name>]
                   [INSTALL_EXPORT_SET <export-name>]
                   [EXCLUDE_FROM_ALL]
                   [<CPM_ARGS> ...])

.. |PKG_NAME| replace:: cuco
.. include:: common_package_args.txt

Result Targets
^^^^^^^^^^^^^^
  cuco::cuco target will be created

Result Variables
^^^^^^^^^^^^^^^^
  :cmake:variable:`cuco_SOURCE_DIR` is set to the path to the source directory of cuco.
  :cmake:variable:`cuco_BINARY_DIR` is set to the path to the build directory of cuco.
  :cmake:variable:`cuco_ADDED`      is set to a true value if cuco has not been added before.
  :cmake:variable:`cuco_VERSION`    is set to the version of cuco specified by the versions.json.

#]=======================================================================]
function(rapids_cpm_cuco)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.cuco")

  include("${rapids-cmake-dir}/cpm/detail/package_info.cmake")
  rapids_cpm_package_info(cuco ${ARGN} VERSION_VAR version FIND_VAR find_args CPM_VAR cpm_find_info
                          TO_INSTALL_VAR to_install)

  include("${rapids-cmake-dir}/cpm/find.cmake")
  rapids_cpm_find(cuco ${version} ${find_args} GLOBAL_TARGETS cuco::cuco CPM_ARGS ${cpm_find_info}
                  OPTIONS "BUILD_TESTS OFF" "BUILD_BENCHMARKS OFF" "BUILD_EXAMPLES OFF"
                          "INSTALL_CUCO ${to_install}")

  include("${rapids-cmake-dir}/cpm/detail/display_patch_status.cmake")
  rapids_cpm_display_patch_status(cuco)

  # Propagate up variables that CPMFindPackage provide
  set(cuco_SOURCE_DIR "${cuco_SOURCE_DIR}" PARENT_SCOPE)
  set(cuco_BINARY_DIR "${cuco_BINARY_DIR}" PARENT_SCOPE)
  set(cuco_ADDED "${cuco_ADDED}" PARENT_SCOPE)
  set(cuco_VERSION ${version} PARENT_SCOPE)
# >>>>>>> END NEW CODE (5a62d8b0)

if (CUDA_BACKEND)
    include("${rapids-cmake-dir}/cpm/_cuco.cmake")
else()
    set(HIP_AS_CUDA ON)
    include("${rapids-cmake-dir}/cpm/hipco.cmake")
endif()
