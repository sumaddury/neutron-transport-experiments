# NeutronTransport

## Setup

```bash
git clone --recurse-submodules <this repo> && cd NeutronTransport
./setup.sh
conda activate openmc-diffgeom
```

`setup.sh` runs three steps, each also usable on its own:

1. `scripts/build_package.sh` builds `recipe/` into the local conda channel `./channel`
2. `conda env create -f environment.yml` creates the env `openmc-diffgeom`
3. `scripts/fetch_data.sh` downloads cross sections into `./data` and stores
   `OPENMC_CROSS_SECTIONS` in the env
