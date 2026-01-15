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
#
# This is the preferred entry point for projects using rapids-cmake
#
# Enforce the minimum required CMake version for all users
cmake_minimum_required(VERSION 3.30.4 FATAL_ERROR)

# Allow users to control which version is used
if(NOT (rapids-cmake-branch OR rapids-cmake-version))
  message(FATAL_ERROR "The CMake variable `rapids-cmake-branch` or `rapids-cmake-version` must be defined"
  )
endif()

# Allow users to control which GitHub repo is fetched
if(NOT rapids-cmake-repo)
  if(DEFINED ENV{RAPIDS_CMAKE_REPO})
    set(rapids-cmake-repo $ENV{RAPIDS_CMAKE_REPO})
  else()
    # Define a default repo if the user doesn't set one
    set(rapids-cmake-repo "ROCm-DS/ROCmDS-CMake")
  endif()
endif()

# Allow users to control which branch is fetched
if(NOT rapids-cmake-branch)
# <<<<<<< OLD CODE from 6b9c3a0 (11c5bc7) - COMMENTED OUT
#   if(DEFINED ENV{RAPIDS_CMAKE_BRANCH})
#     set(rapids-cmake-branch $ENV{RAPIDS_CMAKE_BRANCH})
#   else()
#     # Define a default branch if the user doesn't set one
#     set(rapids-cmake-branch "release/rocmds-26.03")
#   endif()
# endif()
#
# if(NOT rapids-cmake-tag AND DEFINED ENV{RAPIDS_CMAKE_TAG})
#   set(rapids-cmake-tag $ENV{RAPIDS_CMAKE_TAG})
# endif()
#
# if(NOT rapids-cmake-sha AND DEFINED ENV{RAPIDS_CMAKE_SHA})
#   set(rapids-cmake-sha $ENV{RAPIDS_CMAKE_SHA})
# =======
  # Define a default branch if the user doesn't set one
# <<<<<<< OLD CODE from 5d862ab (ed3a9f8) - COMMENTED OUT
# # <<<<<<< OLD CODE from c7726bc (e569e6e) - COMMENTED OUT
# # # <<<<<<< OLD CODE from a736159 (734c43d) - COMMENTED OUT
# # #   set(rapids-cmake-branch "main")
# # # # >>>>>>> END NEW CODE (11c5bc7)
# # # =======
# #   set(rapids-cmake-branch "release/${rapids-cmake-version}")
# # # >>>>>>> END NEW CODE (734c43d)
# # =======
#   set(rapids-cmake-branch "main")
# # >>>>>>> END NEW CODE (e569e6e)
# =======
  set(rapids-cmake-branch "release/${rapids-cmake-version}")
# >>>>>>> END NEW CODE (ed3a9f8)
endif()

# Allow users to control the exact URL passed to FetchContent
if(NOT rapids-cmake-url)
  if(DEFINED ENV{RAPIDS_CMAKE_URL})
    set(rapids-cmake-url "$ENV{RAPIDS_CMAKE_URL}/")
  else()
    # Construct a default URL if the user doesn't set one
    set(rapids-cmake-url "https://github.com/${rapids-cmake-repo}/")
  endif()
  # In order of specificity
  if(rapids-cmake-fetch-via-git)
    if(rapids-cmake-sha)
      # An exact git SHA takes precedence over anything
      set(rapids-cmake-value-to-clone "${rapids-cmake-sha}")
    elseif(rapids-cmake-tag)
      # Followed by a git tag name
      set(rapids-cmake-value-to-clone "${rapids-cmake-tag}")
    else()
      # Or if neither of the above two were defined, use a branch
      set(rapids-cmake-value-to-clone "${rapids-cmake-branch}")
    endif()
  else()
    if(rapids-cmake-sha)
      # An exact git SHA takes precedence over anything
      set(rapids-cmake-value-to-clone "archive/${rapids-cmake-sha}.zip")
    elseif(rapids-cmake-tag)
      # Followed by a git tag name
      set(rapids-cmake-value-to-clone "archive/refs/tags/${rapids-cmake-tag}.zip")
    else()
      # Or if neither of the above two were defined, use a branch
      set(rapids-cmake-value-to-clone "archive/refs/heads/${rapids-cmake-branch}.zip")
    endif()
  endif()
endif()

include(FetchContent)
if(rapids-cmake-fetch-via-git)
  FetchContent_Declare(rapids-cmake GIT_REPOSITORY "${rapids-cmake-url}"
                       GIT_TAG "${rapids-cmake-value-to-clone}")
else()
  string(APPEND rapids-cmake-url "${rapids-cmake-value-to-clone}")
  FetchContent_Declare(rapids-cmake URL "${rapids-cmake-url}")
endif()
FetchContent_GetProperties(rapids-cmake)
if(rapids-cmake_POPULATED)
  # Something else has already populated rapids-cmake, only thing we need to do is setup the
  # CMAKE_MODULE_PATH
  if(NOT "${rapids-cmake-dir}" IN_LIST CMAKE_MODULE_PATH)
    list(APPEND CMAKE_MODULE_PATH "${rapids-cmake-dir}")
  endif()
else()
  FetchContent_MakeAvailable(rapids-cmake)
endif()
