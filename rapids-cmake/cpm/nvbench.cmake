# <<<<<<< OLD CODE from fd70267 (0e5bafc) - COMMENTED OUT
# # <<<<<<< OLD CODE from 56111f7 (4469a94) - COMMENTED OUT
# # # MIT License
# # #
# # # Copyright (c) 2023-2024 Advanced Micro Devices, Inc.
# # #
# # # Permission is hereby granted, free of charge, to any person obtaining a copy
# # # of this software and associated documentation files (the "Software"), to deal
# # # in the Software without restriction, including without limitation the rights
# # # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# # # copies of the Software, and to permit persons to whom the Software is
# # # furnished to do so, subject to the following conditions:
# # #
# # # The above copyright notice and this permission notice shall be included in all
# # # copies or substantial portions of the Software.
# # #
# # # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# # # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# # # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# # # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# # # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# # # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# # # SOFTWARE.
# # =======
# #=============================================================================
# =======
# =============================================================================
# cmake-format: off
# >>>>>>> END NEW CODE (0e5bafc)
# SPDX-FileCopyrightText: Copyright (c) 2021-2025, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
# cmake-format: on
# =============================================================================
include_guard(GLOBAL)

#[=======================================================================[.rst:
rapids_cpm_nvbench
------------------

.. versionadded:: v21.10.00

Allow projects to find or build `nvbench` via `CPM` with built-in
tracking of these dependencies for correct export support.

Uses the version of nvbench :ref:`specified in the version file <cpm_versions>` for consistency
across all RAPIDS projects.

.. code-block:: cmake

  rapids_cpm_nvbench( [BUILD_EXPORT_SET <export-name>]
                      [INSTALL_EXPORT_SET <export-name>]
                      [BUILD_STATIC]
                      [<CPM_ARGS> ...])

.. |PKG_NAME| replace:: nvbench
.. include:: common_package_args.txt

.. versionadded:: v23.12.00

``BUILD_STATIC``
  Will build nvbench statically. No local searching for a previously
  built version will occur.

.. versionchanged:: v24.02.00

NVBench_ENABLE_CUPTI is set to OFF by default.

Result Targets
^^^^^^^^^^^^^^
  nvbench::nvbench target will be created

  nvbench::main target will be created

Result Variables
^^^^^^^^^^^^^^^^
  :cmake:variable:`nvbench_SOURCE_DIR` is set to the path to the source directory of nvbench.
  :cmake:variable:`nvbench_BINARY_DIR` is set to the path to the build directory of  nvbench.
  :cmake:variable:`nvbench_ADDED`      is set to a true value if nvbench has not been added before.
  :cmake:variable:`nvbench_VERSION`    is set to the version of nvbench specified by the versions.json.

#]=======================================================================]
function(rapids_cpm_nvbench)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.nvbench")

  set(build_shared ON)
  if(BUILD_STATIC IN_LIST ARGN)
    set(build_shared OFF)
    set(CPM_DOWNLOAD_nvbench ON) # Since we need static we build from source
    set(CPM_DOWNLOAD_fmt ON) # Make sure we don't link to a preexisting shared fmt
  endif()

  include("${rapids-cmake-dir}/cpm/detail/package_info.cmake")
  rapids_cpm_package_info(nvbench ${ARGN} VERSION_VAR version FIND_VAR find_args CPM_VAR
                          cpm_find_info TO_INSTALL_VAR to_install)

  # CUDA::nvml is an optional package and might not be installed ( aka conda )
  find_package(CUDAToolkit REQUIRED)
  set(nvbench_with_nvml "OFF")
  if(TARGET CUDA::nvml)
    set(nvbench_with_nvml "ON")
  endif()

  include("${rapids-cmake-dir}/cpm/find.cmake")
  rapids_cpm_find(nvbench ${version} ${find_args}
                  GLOBAL_TARGETS nvbench::nvbench nvbench::main
                  CPM_ARGS ${cpm_find_info}
                  OPTIONS "NVBench_ENABLE_NVML ${nvbench_with_nvml}"
                          "NVBench_ENABLE_CUPTI OFF"
                          "NVBench_ENABLE_EXAMPLES OFF"
                          "NVBench_ENABLE_TESTING OFF"
                          "NVBench_ENABLE_INSTALL_RULES ${to_install}"
                          "BUILD_SHARED_LIBS ${build_shared}")

  include("${rapids-cmake-dir}/cpm/detail/display_patch_status.cmake")
  rapids_cpm_display_patch_status(nvbench)
# >>>>>>> END NEW CODE (4469a94)

include_guard(GLOBAL)

option(CUDA_BACKEND "If the CUDA_BACKEND should be used. Defaults to OFF." OFF)

if (CUDA_BACKEND)
    include("${rapids-cmake-dir}/cpm/_nvbench.cmake")
else()
    set(HIP_AS_CUDA ON)
    include("${rapids-cmake-dir}/cpm/hipbench.cmake")
endif()
