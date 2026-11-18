#!/usr/bin/env bash
# Build recipes/ into ./channel (the local conda channel), in dependency order:
#   moab-pymoab -> xdg-geometry -> openmc-diffgeom
# Uses the `openmc-build` env (build-environment.yml), creating it if missing.
# A package whose exact build (name, version, build string) is already in
# ./channel is skipped; `rm -r channel` to force a full rebuild.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"

conda env list | awk '{print $1}' | grep -qx openmc-build || conda env create -f build-environment.yml
PREFIX="$(conda run -n openmc-build printenv CONDA_PREFIX)"
mkdir -p channel
for pkg in moab-pymoab xdg-geometry openmc-diffgeom; do
  echo "package: $pkg"
  conda run -n openmc-build --no-capture-output rattler-build build \
    --recipe "recipes/$pkg" --output-dir channel \
    -m "$PREFIX/conda_build_config.yaml" -m recipes/variants.yaml --ignore-recipe-variants \
    --skip-existing=local
done
