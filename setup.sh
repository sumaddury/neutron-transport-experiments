#!/usr/bin/env bash
# One command on a fresh machine (needs only conda + git + curl):
#   git clone --recurse-submodules <repo> && cd <repo> && ./setup.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
git submodule update --init --recursive
scripts/build_package.sh                                   # recipe/ -> ./channel
if conda env list | awk '{print $1}' | grep -qx openmc-diffgeom; then
  conda env update -n openmc-diffgeom -f environment.yml --prune
else
  conda env create -f environment.yml
fi
scripts/fetch_data.sh openmc-diffgeom                      # ./data + OPENMC_CROSS_SECTIONS
echo "Done. Activate with: conda activate openmc-diffgeom"
