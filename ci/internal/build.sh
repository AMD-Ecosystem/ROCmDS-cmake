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

# Build the ROCmDS-CMake packages.
#
# This project ships CMake modules rather than compiled artifacts, so the build
# is a configure step followed by CPack.
#
# Required environment variables:
#   SRC_DIR              Parent directory of the project checkout.
#   BUILD_DIR            Scratch directory for the build tree.
#   INSTALL_DIR          Prefix the packages are built for.
#   BUILD_ARTIFACTS_DIR  Destination for the packages.
#
# Optional environment variables:
#   PROJECT_ID                    Checkout directory name under SRC_DIR
#                                 (default: rocmds_cmake).
#   CMAKE_INSTALL_PREFIX          Install prefix, overriding INSTALL_DIR.
#   CPACK_PACKAGING_INSTALL_PREFIX  Prefix baked into the packages. Defaults to
#                                 the install prefix.
#   ROCMDS_CMAKE_CPACK_GENERATORS Semicolon separated CPack generator list.
#                                 Defaults to the generators whose backend is
#                                 present (RPM and/or DEB).
#   CMAKE_VERSION                 Version of the cmake package to install into
#                                 the venv under BUILD_DIR that supplies cmake,
#                                 cpack and ctest. Unset means whatever cmake is
#                                 on PATH.

set -xeu

: "${SRC_DIR:?SRC_DIR must be set}"
: "${BUILD_DIR:?BUILD_DIR must be set}"
: "${INSTALL_DIR:?INSTALL_DIR must be set}"
: "${BUILD_ARTIFACTS_DIR:?BUILD_ARTIFACTS_DIR must be set}"

PROJECT_ID="${PROJECT_ID:-rocmds_cmake}"
install_prefix="${CMAKE_INSTALL_PREFIX:-${INSTALL_DIR}}"
package_prefix="${CPACK_PACKAGING_INSTALL_PREFIX:-${install_prefix}}"

#### packaging backends

if [ -n "${ROCMDS_CMAKE_CPACK_GENERATORS:-}" ]; then
  cpack_generators="${ROCMDS_CMAKE_CPACK_GENERATORS}"
else
  detected=()
  if command -v rpmbuild >/dev/null 2>&1; then
    detected+=("RPM")
  fi
  if command -v dpkg-deb >/dev/null 2>&1; then
    detected+=("DEB")
  fi
  cpack_generators="$(IFS=';'; echo "${detected[*]:-}")"
fi

if [ -z "${cpack_generators}" ]; then
  echo "ERROR: no CPack backend available (need rpmbuild and/or dpkg-deb)" >&2
  exit 2
fi

#### configure and package

src_dir="${SRC_DIR}/${PROJECT_ID}"
build_src_dir="${BUILD_DIR}/${PROJECT_ID}"
build_build_dir="${build_src_dir}/build"

rm -rf "${build_src_dir}"
mkdir -p "${BUILD_DIR}"
cp -R "${src_dir}" "${build_src_dir}"

mkdir -p "${BUILD_ARTIFACTS_DIR}"

# cmake, cpack and ctest come from this venv.
if [ -n "${CMAKE_VERSION:-}" ]; then
  python3 --version
  python3 -m venv "${build_src_dir}/_venv"
  # shellcheck disable=SC1091
  . "${build_src_dir}/_venv/bin/activate"
  pip3 install --upgrade pip
  pip3 install "cmake==${CMAKE_VERSION}"
fi
cmake --version && cpack --version && ctest --version

cmake -S "${build_src_dir}" -B "${build_build_dir}" \
  -D RAPIDS_CMAKE_ONLY_CREATE_PACKAGE=ON \
  -D "CMAKE_INSTALL_PREFIX=${install_prefix}" \
  -D "CPACK_PACKAGING_INSTALL_PREFIX=${package_prefix}" \
  -D "CPACK_OUTPUT_FILE_PREFIX=${BUILD_ARTIFACTS_DIR}"

# This project has no build step; the packages come straight from the
# configured tree.
cpack --config "${build_build_dir}/CPackConfig.cmake" -G "${cpack_generators}"

ls -l "${BUILD_ARTIFACTS_DIR}"
