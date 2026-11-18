#!/bin/bash
set -euxo pipefail

# 1. C++ library, headers, tools and MOABConfig.cmake. Fortran (and so
#    BLAS/LAPACK) is off; Eigen covers MOAB's small dense linear algebra.
cmake ${CMAKE_ARGS} \
      -S . -B build_cmake \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DENABLE_HDF5=ON -DHDF5_ROOT="${PREFIX}" \
      -DENABLE_EIGEN3=ON \
      -DENABLE_FORTRAN=OFF -DENABLE_BLASLAPACK=OFF \
      -DENABLE_MPI=OFF -DENABLE_PYMOAB=OFF -DENABLE_TESTING=OFF
cmake --build build_cmake --parallel "${CPU_COUNT}"
cmake --install build_cmake

# MOAB's exported target links to HDF5's CMake targets (hdf5-shared,
# hdf5_hl-shared), and MOABConfig.cmake is meant to define them by including
# HDF5's config, but it looks under ${HDF5_DIR}/share/cmake/hdf5/, while
# conda's HDF5_DIR is already lib/cmake/hdf5. Point it at the real file, or
# consumers (XDG) get "-lhdf5_hl-shared" on their link line.
sed -i.bak 's#/share/cmake/hdf5/hdf5-config.cmake#/hdf5-config.cmake#g' \
    "${PREFIX}/lib/cmake/MOAB/MOABConfig.cmake"
rm "${PREFIX}/lib/cmake/MOAB/MOABConfig.cmake.bak"
grep -q 'lib/cmake/hdf5/hdf5-config.cmake' "${PREFIX}/lib/cmake/MOAB/MOABConfig.cmake"

# 2. pymoab, compiled against the library just installed in $PREFIX.
mkdir -p pymoab_build
cp -r pymoab pymoab_build/
cp "${RECIPE_DIR}/setup_pymoab.py" pymoab_build/setup.py
cd pymoab_build
MOAB_VERSION="${PKG_VERSION}" MOAB_SOURCE_DIR="${SRC_DIR}" MOAB_BUILD_DIR="${SRC_DIR}/build_cmake" \
  "${PYTHON}" -m pip install . -vv --no-deps --no-build-isolation
