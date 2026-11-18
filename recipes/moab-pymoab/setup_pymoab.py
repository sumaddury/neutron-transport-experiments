"""Build pymoab against an installed MOAB (libMOAB in $PREFIX).

Adapted from MOAB's deprecated/pymoab/setup.py.cmake: like upstream, the
headers come from the source and CMake build trees, because pymoab also uses
internal headers (e.g. TagInfo.hpp) that MOAB does not install. Linking and
the runtime path use the installed library.
"""
import os
from pathlib import Path

import numpy as np
from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup

prefix = Path(os.environ["PREFIX"])
source = Path(os.environ["MOAB_SOURCE_DIR"])
build = Path(os.environ["MOAB_BUILD_DIR"])
include_dirs = [str(source / "src" / "moab"), str(source / "src"), str(build / "src"),
                np.get_include(), "pymoab"]

extensions = [
    Extension(
        f"pymoab.{pyx.stem}",
        [str(pyx)],
        language="c++",
        include_dirs=include_dirs,
        library_dirs=[str(prefix / "lib")],
        runtime_library_dirs=[str(prefix / "lib")],
        libraries=["MOAB"],
        define_macros=[("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")],
    )
    for pyx in sorted(Path("pymoab").glob("*.pyx"))
]

setup(
    name="pymoab",
    version=os.environ["MOAB_VERSION"],
    packages=find_packages(),
    package_data={"pymoab": ["*.pxd"]},
    ext_modules=cythonize(extensions, include_path=["pymoab"]),
)
