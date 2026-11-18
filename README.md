# NeutronTransport

## Setup

```bash
git clone --recurse-submodules <this repo> && cd NeutronTransport
./setup.sh
conda activate openmc-diffgeom
```

`setup.sh` runs three steps, each also usable on its own:

1. `scripts/build_package.sh` builds `recipes/` into the local conda channel `./channel`
2. `conda env create -f environment.yml` creates the env `openmc-diffgeom`
3. `scripts/fetch_data.sh` downloads cross sections into `./data` and stores
   `OPENMC_CROSS_SECTIONS` in the env

`recipes/` holds three conda recipes, built in this order:

| Recipe | What | Why it is built here |
| --- | --- | --- |
| `moab-pymoab` | MOAB 5.6.0 (HDF5) + `pymoab` | conda-forge's `moab` has no Python bindings; pymoab is not on PyPI |
| `xdg-geometry` | XDG mesh ray tracing (MOAB + Embree) | not packaged anywhere |
| `openmc-diffgeom` | OpenMC `diff-geom` branch, XDG on | the derivative engine |

To change a version, edit `commit`/`tag` in that recipe's `recipe.yaml` and
make the package version or `build_number` increase (see the comment in each
recipe); otherwise the old build in `./channel` is reused or even preferred.
For `openmc-diffgeom`, also raise the floor in `environment.yml`. The same env
runs the root CSG scripts and `openmc-derivative-testing/surface_mesh`.

## Log

- Added `transport_options` parameter that sets batch size and batch number
- Added arguments in `optimizer.__main__` for batch size and number
- Added flag `--no-trigger` to toggle the relative-error trigger, if exact batch number control is needed
- Added the above to evaluation metadata
- Added seeding controls for `openmc` randomness
- Added batch trace script to get per-batch means
