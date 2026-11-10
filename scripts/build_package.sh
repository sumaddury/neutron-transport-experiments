#!/usr/bin/env bash
# Build recipe/ into ./channel (the local conda channel). Uses the
# `openmc-build` env (build-environment.yml), creating it if missing.
# Skips if a package for this platform is already in ./channel; `rm -r channel` to force.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"

if compgen -G "channel/*/openmc-diffgeom-*" >/dev/null; then
  echo "package: already built in ./channel (rm -r channel to rebuild)"; exit 0
fi
conda env list | awk '{print $1}' | grep -qx openmc-build || conda env create -f build-environment.yml
PREFIX="$(conda run -n openmc-build printenv CONDA_PREFIX)"
conda run -n openmc-build --no-capture-output rattler-build build \
  --recipe recipe --output-dir channel \
  -m "$PREFIX/conda_build_config.yaml" -m recipe/variants.yaml --ignore-recipe-variants
