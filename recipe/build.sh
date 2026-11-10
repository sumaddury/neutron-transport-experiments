#!/bin/bash
set -euxo pipefail

# Newer C++ features with the old macOS SDK (conda-forge knowledge base).
export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

# Deterministic version string (the source tree has no usable git tags).
export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_OPENMC="${OPENMC_VERSION}+g${OPENMC_COMMIT:0:9}"

# C++ library + `openmc` executable. Build dir must not be named `build`:
# setuptools stages the Python API in build/lib.
cmake ${CMAKE_ARGS} \
      -S . -B build_cmake \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=Release \
      -DHDF5_ROOT="${PREFIX}" \
      -DOPENMC_USE_OPENMP=ON \
      -DOPENMC_BUILD_TESTS=OFF
cmake --build build_cmake --parallel "${CPU_COUNT}"
cmake --install build_cmake

# Python API
"${PYTHON}" -m pip install . -vv --no-deps --no-build-isolation
