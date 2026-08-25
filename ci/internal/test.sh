#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2026 Advanced Micro Devices, Inc.
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

# Exercise the ROCmDS-CMake modules the way consumers use them: build and
# install the package, then configure the in-tree tests and examples against
# both an installed package and a downloaded RAPIDS.cmake.
#
# Required environment variables:
#   SRC_DIR  Parent directory of the project checkout.
#
# Optional environment variables:
#   PROJECT_ID     Checkout directory name (default: rocmds_cmake).
#   ROCM_PATH      Added to CMAKE_PREFIX_PATH.
#   CMAKE_VERSION  Version of the cmake package to install into a scratch venv
#                  that supplies cmake and cpack. Unset means whatever cmake is
#                  on PATH.

set -xeu

: "${SRC_DIR:?SRC_DIR must be set}"

PROJECT_ID="${PROJECT_ID:-rocmds_cmake}"

printenv

os_id=$(. /etc/os-release && echo "${ID}")
os_id_like=$(. /etc/os-release && echo "${ID_LIKE}")

build_dir=$(mktemp -d)
cmake_venv_dir=$(mktemp -d)

cp -av "${SRC_DIR}/${PROJECT_ID}/." "${build_dir}/"

# cmake and cpack come from this venv. It sits outside build_dir so it cannot
# end up in the package the tests build there.
if [ -n "${CMAKE_VERSION:-}" ]; then
  python3 --version
  python3 -m venv "${cmake_venv_dir}/_venv"
  # shellcheck disable=SC1091
  . "${cmake_venv_dir}/_venv/bin/activate"
  pip3 install --upgrade pip
  pip3 install "cmake==${CMAKE_VERSION}"
fi
cmake --version && cpack --version && ctest --version

function package_format() {
  if [[ "${os_id_like}" == *"debian"* ]]; then
    echo DEB
  elif [[ "${os_id_like}" == *"rhel"* ]]; then
    echo RPM
  else
    echo "ERROR: OS '${os_id}' not handled yet." >&2
    exit 1
  fi
}

pkg_fmt=$(package_format)

function create_and_install_package() {
  cd "${build_dir}" || exit 1
  # test packaging and package installation
  rm -rf build_pkg
  mkdir build_pkg
  cd build_pkg || exit 1
  cmake -D RAPIDS_CMAKE_ONLY_CREATE_PACKAGE=ON ..
  cpack -G "${pkg_fmt}"
  if [[ "${pkg_fmt}" == "DEB" ]]; then
    apt install -y ./dist/rocmds-cmake-dev*.deb
    dpkg -L rocmds-cmake-dev
  else
    yum install -y ./dist/rocmds-cmake-devel*.rpm
  fi
}

function remove_package() {
  if [[ "${pkg_fmt}" == "DEB" ]]; then
    apt remove -y rocmds-cmake-dev
  else
    yum remove -y rocmds-cmake-devel
  fi
}

function run_hip_amd_tests() {
  cd "${build_dir}/testing" || exit 1
  rm -rf build
  mkdir build
  cd build || exit 1
  cmake ../
}

function run_example_hip() {
  echo "example-hip"
  cd "${build_dir}/example-hip" || exit 1
  rm -rf build
  mkdir build
  cd build || exit 1
  cmake ../
}

function run_example_from_module() {
  echo "example-from-module"
  export RAPIDS_CMAKE_MODULE_PATH=/opt/rocm-ds/share/cmake/rocmds-cmake/modules
  cd "${build_dir}/example-from-module" || exit 1
  rm -rf build
  mkdir build
  cd build || exit 1
  cmake ../ -D "CMAKE_MODULE_PATH=${RAPIDS_CMAKE_MODULE_PATH}" -D CMAKE_HIP_ARCHITECTURES="gfx90a"
}

## main

export CPM_DOWNLOAD_ALL="ON" # NOTE: make ROCmDS-CMake tests reproducible
                             #       by always using CPMAddPackage, i.e.,
                             #       never using local packages.
export CMAKE_PREFIX_PATH="${ROCM_PATH:-/opt/rocm}/lib/cmake"

# NOTE: this has to patch the copy the tests actually run against.
VERSIONS_JSON="${build_dir}/rapids-cmake/cpm/versions.json"
cp "${VERSIONS_JSON}" "${VERSIONS_JSON}.orig"

export ROCMDS_LOGGER_GIT_URL="https://github.com/AMD-AIOSS/rocmds-logger"
export ROCMDS_LOGGER_GIT_TAG="feat/docharri/branch-25.02"
export HIPCOLLECTIONS_GIT_URL="https://github.com/AMD-AIOSS/hipcollections"
export HIPCOLLECTIONS_GIT_TAG="amd-integration/branch-2.0.0-rocm-ds-25.03"
export HIPBENCH_GIT_URL="https://github.com/AMD-AIOSS/hipbench"
export HIPBENCH_GIT_TAG="amd-integration/branch-1.0.0-rocm-ds-25.03"

jq \
  --arg ROCMDS_LOGGER_GIT_URL "${ROCMDS_LOGGER_GIT_URL}" \
  --arg ROCMDS_LOGGER_GIT_TAG "${ROCMDS_LOGGER_GIT_TAG}" \
  --arg HIPBENCH_GIT_URL "${HIPBENCH_GIT_URL}" \
  --arg HIPBENCH_GIT_TAG "${HIPBENCH_GIT_TAG}" \
  --arg HIPCOLLECTIONS_GIT_URL "${HIPCOLLECTIONS_GIT_URL}" \
  --arg HIPCOLLECTIONS_GIT_TAG "${HIPCOLLECTIONS_GIT_TAG}" \
  '
        .packages.rocmds_logger.git_url = $ROCMDS_LOGGER_GIT_URL |
        .packages.rocmds_logger.git_tag = $ROCMDS_LOGGER_GIT_TAG |
        .packages.hipbench.git_url = $HIPBENCH_GIT_URL |
        .packages.hipbench.git_tag = $HIPBENCH_GIT_TAG |
        .packages.hipco.git_url = $HIPCOLLECTIONS_GIT_URL |
        .packages.hipco.git_tag = $HIPCOLLECTIONS_GIT_TAG
    ' "${VERSIONS_JSON}.orig" > "${VERSIONS_JSON}"

cat "${VERSIONS_JSON}"

if [[ -n "${CONDA_PREFIX:-}" ]]; then
  # only certain tests/examples are prepared to be run within a conda environment

  # use package
  echo "use preinstalled package (conda env activated)"
  create_and_install_package
  run_example_hip
  remove_package

  # download rapids-cmake file
  echo "download RAPIDS.cmake file (conda env activated)"
  unset RAPIDS_CMAKE_MODULE_PATH
  run_example_hip

  conda deactivate
fi

# use package
echo "use preinstalled package (conda env deactivated)"
create_and_install_package
run_hip_amd_tests
run_example_hip
run_example_from_module
remove_package

# download rapids-cmake file
echo "download RAPIDS.cmake file (conda env deactivated)"
unset RAPIDS_CMAKE_MODULE_PATH
run_hip_amd_tests
run_example_hip

# clean up
rm -r "${build_dir}" "${cmake_venv_dir}"

echo "OK"
