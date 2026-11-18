#!/bin/bash
set -euxo pipefail

# Newer C++ features with the old macOS SDK (conda-forge knowledge base).
export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

# Only vendor/linalg is needed with tests, tools and examples off. fmt is
# found in $PREFIX, so the vendored copy is skipped.
git submodule update --init vendor/linalg

cmake ${CMAKE_ARGS} \
      -S . -B build_cmake \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=Release \
      -DXDG_ENABLE_MOAB=ON -DMOAB_DIR="${PREFIX}/lib/cmake/MOAB" \
      -DXDG_ENABLE_EMBREE=ON \
      -DXDG_ENABLE_LIBMESH=OFF -DXDG_ENABLE_MFEM=OFF -DXDG_ENABLE_GPRT=OFF \
      -DXDG_BUILD_TESTS=OFF -DXDG_BUILD_TOOLS=OFF -DXDG_BUILD_EXAMPLES=OFF \
      -DXDG_GIT_SUBMODULE=OFF
cmake --build build_cmake --parallel "${CPU_COUNT}"
cmake --install build_cmake
