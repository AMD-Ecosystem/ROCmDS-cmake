# =============================================================================
# cmake-format: off
# SPDX-FileCopyrightText: Copyright (c) 2021-2025, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
# <<<<<<< OLD CODE from fd70267 (0e5bafc) - COMMENTED OUT
# #=============================================================================
# # MIT License
# #
# # Modifications Copyright (c) 2023-2024 Advanced Micro Devices, Inc.
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
# #=============================================================================
# =======
# cmake-format: on
# =============================================================================
# >>>>>>> END NEW CODE (0e5bafc)

cmake_minimum_required(VERSION 3.30.4 FATAL_ERROR)
project(rapids-cmake-testing LANGUAGES NONE)

enable_testing()
include(utils/cmake_config_test.cmake)
include(utils/cmake_ctest_test.cmake)
include(utils/cmake_build_test.cmake)

option(CUDA_BACKEND "Use the CUDA backend" OFF)

if (CUDA_BACKEND)
  set(RAPIDS_CMAKE_PLATFORM "cuda")
else()
  set(RAPIDS_CMAKE_PLATFORM "hip")
endif()

add_subdirectory(cmake)
message(STATUS "RAPIDS_CMAKE_PLATFORM=${RAPIDS_CMAKE_PLATFORM}")
add_subdirectory(${RAPIDS_CMAKE_PLATFORM})
add_subdirectory(export)
add_subdirectory(find)

include("${CMAKE_CURRENT_SOURCE_DIR}/utils/determine_gpu_count.cmake")
determine_gpu_count()
add_subdirectory(test)

option(RAPIDS_CMAKE_ENABLE_DOWNLOAD_TESTS "Enable tests that require downloads" ON)
if(RAPIDS_CMAKE_ENABLE_DOWNLOAD_TESTS)
  # Setup and fill the cpm cache, and specify CPM_SOURCE_CACHE so that all subsequent tests in this
  # directory use the shared CPM_SOURCE_CACHE
  include("${CMAKE_CURRENT_SOURCE_DIR}/utils/setup_cpm_cache.cmake")
  setup_cpm_cache()

  add_subdirectory(cpm)
  add_subdirectory(cython-core)
  add_subdirectory(other)
endif()
