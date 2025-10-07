# MIT License
#
# Copyright (c) 2023-2024 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# <<<<<<< OLD CODE from 1cdd747 (bad4f29) - COMMENTED OUT
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
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=============================================================================
include_guard(GLOBAL)

#[=======================================================================[.rst:
rapids_cpm_cccl
---------------

.. versionadded:: v24.02.00

Allow projects to find or build `CCCL` via `CPM` with built-in
tracking of these dependencies for correct export support.

Uses the version of CCCL :ref:`specified in the version file <cpm_versions>` for consistency
across all RAPIDS projects.

When `BUILD_EXPORT_SET` is specified the generated build export set dependency
file will automatically call `thrust_create_target(CCCL::Thrust FROM_OPTIONS)`.

When `INSTALL_EXPORT_SET` is specified the generated install export set dependency
file will automatically call `thrust_create_target(CCCL::Thrust FROM_OPTIONS)`.

.. code-block:: cmake

  rapids_cpm_cccl( [BUILD_EXPORT_SET <export-name>]
                   [INSTALL_EXPORT_SET <export-name>]
                   [ENABLE_UNSTABLE]
                   [<CPM_ARGS> ...])

``ENABLE_UNSTABLE``
  Enable unstable features in CCCL.

.. |PKG_NAME| replace:: CCCL
.. include:: common_package_args.txt

Result Targets
^^^^^^^^^^^^^^
  CCCL::CCCL target will be created
  CCCL::Thrust target will be created
  CCCL::libcudacxx target will be created
  CCCL::CUB target will be created
  libcudacxx::libcudacxx target will be created
  CCCL::cudax target will be created (if ENABLE_UNSTABLE is specified)

Result Variables
^^^^^^^^^^^^^^^^
  :cmake:variable:`CCCL_SOURCE_DIR` is set to the path to the source directory of CCCL.
  :cmake:variable:`CCCL_BINARY_DIR` is set to the path to the build directory of CCCL.
  :cmake:variable:`CCCL_ADDED`      is set to a true value if CCCL has not been added before.
  :cmake:variable:`CCCL_VERSION`    is set to the version of CCCL specified by the versions.json.

#]=======================================================================]
# cmake-lint: disable=R0915
function(rapids_cpm_cccl)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.cccl")

  set(options ENABLE_UNSTABLE)
  set(one_value)
  set(multi_value)
  cmake_parse_arguments(_RAPIDS "${options}" "${one_value}" "${multi_value}" ${ARGN})

  include("${rapids-cmake-dir}/cpm/detail/package_info.cmake")
  rapids_cpm_package_info(CCCL ${_RAPIDS_UNPARSED_ARGUMENTS} VERSION_VAR version FIND_VAR find_args
                          CPM_VAR cpm_find_info TO_INSTALL_VAR to_install)

  if(_RAPIDS_ENABLE_UNSTABLE)
    list(APPEND cpm_find_info OPTIONS "CCCL_ENABLE_UNSTABLE ON")
  endif()

  if(to_install)
    # Make sure we install CCCL into the `include/rapids` subdirectory instead of the default
    include(GNUInstallDirs)
    string(APPEND CMAKE_INSTALL_INCLUDEDIR "/rapids")
    string(APPEND CMAKE_INSTALL_LIBDIR "/rapids")
    # We don't specify `CCCL_ENABLE_INSTALL_RULES` as a `rapids_cpm_find` argument so that it isn't
    # propagated to users of the build export file which would cause them to also install parts of
    # CCCL by mistake ( and in a wrong directory )
    get_property(rapids_cccl_install_rules_already_called GLOBAL
                 PROPERTY rapids_cmake_cccl_install_rules SET)
    if(NOT rapids_cccl_install_rules_already_called)
      set(CCCL_ENABLE_INSTALL_RULES ON)
      set(CUB_ENABLE_INSTALL_RULES ON)
      set(Thrust_ENABLE_INSTALL_RULES ON)
      set(libcudacxx_ENABLE_INSTALL_RULES ON)
      set_property(GLOBAL PROPERTY rapids_cmake_cccl_install_rules ON)
    endif()
  endif()

  include("${rapids-cmake-dir}/cpm/find.cmake")
  rapids_cpm_find(CCCL ${version} ${find_args} GLOBAL_TARGETS CCCL CCCL::CCCL CCCL::CUB
                                                              CCCL::libcudacxx CCCL::cudax
                  CPM_ARGS FIND_PACKAGE_ARGUMENTS EXACT ${cpm_find_info})

  include("${rapids-cmake-dir}/cpm/detail/display_patch_status.cmake")
  rapids_cpm_display_patch_status(CCCL)

  if(CCCL_SOURCE_DIR)
    # Store where CMake can find the cccl-config.cmake
    include("${rapids-cmake-dir}/export/find_package_root.cmake")
    rapids_export_find_package_root(BUILD CCCL "${CCCL_SOURCE_DIR}/lib/cmake/cccl"
                                    EXPORT_SET ${_RAPIDS_BUILD_EXPORT_SET})
    rapids_export_find_package_root(INSTALL CCCL
                                    [=[${CMAKE_CURRENT_LIST_DIR}/../../rapids/cmake/cccl]=]
                                    EXPORT_SET ${_RAPIDS_INSTALL_EXPORT_SET} CONDITION to_install)
  endif()
# >>>>>>> END NEW CODE (bad4f29)

include_guard(GLOBAL)

option(CUDA_BACKEND "If the CUDA_BACKEND should be used. Defaults to OFF." OFF)

if (CUDA_BACKEND)
    include("${rapids-cmake-dir}/cpm/_cccl.cmake")
else()
    set(HIP_AS_CUDA ON)
    include("${rapids-cmake-dir}/cpm/hipccl.cmake")
endif()
