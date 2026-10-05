# scripts

Build and packaging helper scripts for `pto_kernels`.

## run_sim_tests.sh

Runs the pytest suite against the CANN CA model — no NPU required. Every batch of
test ids is launched in its own `msprof op simulator` process, so a case that
stalls the simulator or overruns msprof's `--timeout` only costs its batch
instead of truncating the run.

**Usage**

```bash
./scripts/run_sim_tests.sh [test-path-or-node-id ...]
```

| Environment | Default | Description |
|-------------|---------|-------------|
| `ASCEND_HOME_PATH` / `ASCEND_TOOLKIT_HOME` | — | CANN installation to simulate against (required) |
| `MSPROF_SOC_VERSION` | `Ascend910B2` | CA-model target |
| `NPU_DEVICE` | `npu:0` | Device string the tests bind to (a bare index is rejected) |
| `BATCH_SIZE` | `8` | Test ids per `msprof` run; `0` runs the whole selection in one process |
| `BUDGET` | `900` | Wall-clock seconds per batch |
| `MSPROF_TIMEOUT` | `BUDGET - 60` | msprof's own `--timeout` |
| `KEEP_SIM_OUT` | `0` | Keep the msprof output directory |

**Examples**

```bash
# whole suite, batches of 8
./scripts/run_sim_tests.sh

# one file, smaller batches and a longer budget
BATCH_SIZE=4 BUDGET=1800 ./scripts/run_sim_tests.sh tests/test_tri_inv_ns.py
```

Tests marked `requires_device` are skipped automatically under the CA model
(flash attention, for example, needs a real FFTS control address).

## build.sh

Compiles the project locally using CMake against an Ascend CANN toolkit installation.

**Usage**

```bash
./scripts/build.sh [--soc-version <version>]
```

| Option | Default | Description |
|--------|---------|-------------|
| `-v`, `--soc-version` | `Ascend910B4` | Target SoC version passed to CMake as `-DSOC_VERSION` |

The script resolves the Ascend toolkit path from `$ASCEND_INSTALL_PATH`, `$ASCEND_HOME_PATH`, `~/Ascend/ascend-toolkit/latest`, or `/usr/local/Ascend/ascend-toolkit/latest` (in that order), sources its environment, then runs a clean CMake configure + build.

## gen-wheel.sh

Builds a `manylinux` Python wheel inside a Docker container, replicating the steps from `.github/workflows/python-packaging.yml`.

The container image used is `quay.io/ascend/manylinux:9.0.0-910b-manylinux_2_28-<python_version>`. The repo is mounted at `/workspace` and the following steps are executed inside the container:

1. Source Ascend toolkit and ATB environment files.
2. Install build dependencies (`pyyaml`, `setuptools`, `pytest`, `packaging`, `pybind11[global]`, `requirements.txt`).
3. Run `make clean wheel`.
4. Install and inspect the built wheel.
5. Run `auditwheel repair` with the appropriate `--exclude` flags for Ascend/PyTorch shared libraries.
6. Write the repaired wheel to `wheelhouse/`.

**Usage**

```bash
./scripts/gen-wheel.sh [--arch x86_64|aarch64] [--py-ver 310|311]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--arch` | `x86_64` | Target architecture (`x86_64` or `aarch64`) |
| `--py-ver` | `310` | Python version without dots (`310` or `311`) |

**Examples**

```bash
# x86_64, Python 3.10 (defaults)
./scripts/gen-wheel.sh

# aarch64, Python 3.11
./scripts/gen-wheel.sh --arch aarch64 --py-ver 311
```

The repaired wheel is written to `wheelhouse/pto_kernels*manylinux*.whl` in the repository root.
