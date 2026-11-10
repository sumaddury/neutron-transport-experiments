#!/usr/bin/env bash
# Download ENDF/B-VII.1 HDF5 cross sections (1.7 GB) into ./data and register
# OPENMC_CROSS_SECTIONS as a variable of a conda environment.
#   scripts/fetch_data.sh [ENV_NAME]        (default: openmc-diffgeom)
# Safe to re-run: skips the download if a valid library is already in place.
set -euo pipefail

ENV_NAME="${1:-openmc-diffgeom}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
URL="https://anl.box.com/shared/static/9igk353zpy8fn9ttvtrqgzvw1vtejoz6.xz"
SHA256="5bc4b62a602d569e3a801c3499f03378192e83623c3eb39500804178706781f9"
LIB="$ROOT/data/endfb-vii.1-hdf5"
XS="$LIB/cross_sections.xml"

valid() { [[ -f "$XS" ]] && grep -q 'c_H_in_H2O' "$XS"; }

if valid; then
  echo "data: already present at $LIB"
else
  mkdir -p "$ROOT/data"
  tmp="$(mktemp -d "$ROOT/data/.dl.XXXXXX")"; trap 'rm -rf "$tmp"' EXIT
  echo "data: downloading (1.7 GB) ..."
  curl -fL --retry 3 -C - -o "$tmp/lib.tar.xz" "$URL"
  got="$( (sha256sum "$tmp/lib.tar.xz" 2>/dev/null || shasum -a 256 "$tmp/lib.tar.xz") | cut -d' ' -f1)"
  [[ "$got" == "$SHA256" ]] || { echo "checksum mismatch: $got" >&2; exit 1; }
  tar -xJf "$tmp/lib.tar.xz" -C "$tmp"
  [[ -f "$tmp/endfb-vii.1-hdf5/cross_sections.xml" ]] \
    && grep -q 'c_H_in_H2O' "$tmp/endfb-vii.1-hdf5/cross_sections.xml" \
    || { echo "extracted library is invalid" >&2; exit 1; }
  rm -rf "$LIB"; mv "$tmp/endfb-vii.1-hdf5" "$LIB"
  echo "data: installed at $LIB"
fi

# Stored in the env itself; applied on every `conda activate`.
conda env config vars set -n "$ENV_NAME" OPENMC_CROSS_SECTIONS="$XS" >/dev/null
echo "env '$ENV_NAME': OPENMC_CROSS_SECTIONS=$XS (re-activate the env to apply)"
