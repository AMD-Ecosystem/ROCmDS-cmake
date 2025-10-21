# <<<<<<< OLD CODE from 56111f7 (4469a94) - COMMENTED OUT
# # MIT License
# #
# # Copyright (c) 2023-2024 Advanced Micro Devices, Inc.
# #
# # Permission is hereby granted, free of charge, to any person obtaining a copy
# # of this software and associated documentation files (the "Software"), to deal
# # in the Software without restriction, including without limitation the rights
# # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# # copies of the Software, and to permit persons to whom the Software is
# # furnished to do so, subject to the following conditions:
# #
# # The above copyright notice and this permission notice shall be included in all
# # copies or substantial portions of the Software.
# #
# # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# # SOFTWARE.
# =======
#=============================================================================
# SPDX-FileCopyrightText: Copyright (c) 2021-2025, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
#=============================================================================
include_guard(GLOBAL)

#[=======================================================================[.rst:
rapids_cpm_rmm
--------------

.. versionadded:: v21.10.00

Allow projects to find or build `RMM` via `CPM` with built-in
tracking of these dependencies for correct export support.

Uses the current rapids-cmake version of RMM `as specified in the version file <cpm_versions>`
for  consistency across all RAPIDS projects.

.. code-block:: cmake

  rapids_cpm_rmm( [BUILD_EXPORT_SET <export-name>]
                  [INSTALL_EXPORT_SET <export-name>]
                  [<CPM_ARGS> ...])

.. |PKG_NAME| replace:: rmm
.. include:: common_package_args.txt

Result Targets
^^^^^^^^^^^^^^
  rmm::rmm target will be created
  rmm::rmm_logger target will be created
  rmm::rmm_logger_impl target will be created

Result Variables
^^^^^^^^^^^^^^^^
  :cmake:variable:`rmm_SOURCE_DIR` is set to the path to the source directory of RMM.
  :cmake:variable:`rmm_BINARY_DIR` is set to the path to the build directory of  RMM.
  :cmake:variable:`rmm_ADDED`      is set to a true value if RMM has not been added before.
  :cmake:variable:`rmm_VERSION`    is set to the version of RMM specified by the versions.json.

#]=======================================================================]
function(rapids_cpm_rmm)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.rmm")

  include("${rapids-cmake-dir}/cpm/detail/package_info.cmake")
  rapids_cpm_package_info(rmm ${ARGN} VERSION_VAR version FIND_VAR find_args CPM_VAR cpm_find_info
                          TO_INSTALL_VAR to_install)

  include("${rapids-cmake-dir}/cpm/find.cmake")
  rapids_cpm_find(rmm ${version} ${find_args} GLOBAL_TARGETS rmm::rmm rmm::rmm_logger
                                                             rmm::rmm_logger_impl
                  CPM_ARGS ${cpm_find_info} OPTIONS "BUILD_TESTS OFF" "BUILD_BENCHMARKS OFF")
# >>>>>>> END NEW CODE (4469a94)

include_guard(GLOBAL)

option(CUDA_BACKEND "If the CUDA_BACKEND should be used. Defaults to OFF." OFF)

if (CUDA_BACKEND)
    include("${rapids-cmake-dir}/cpm/_rmm.cmake")
else()
    set(HIP_AS_CUDA ON)
    include("${rapids-cmake-dir}/cpm/hipmm.cmake")
endif()
