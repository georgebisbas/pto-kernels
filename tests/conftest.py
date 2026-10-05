import pytest
import os
import torch

NPU_DEVICE = os.environ.get("NPU_DEVICE", "npu:1")
torch.npu.config.allow_internal_format = False
torch.npu.set_device(NPU_DEVICE)


@pytest.fixture(scope="session")
def npu_device():
    return NPU_DEVICE


def _under_ca_model() -> bool:
    """True when the CA model drives the run (`scripts/run_sim_tests.sh` sets PTO_SIMULATOR)."""
    return os.environ.get("PTO_SIMULATOR", "").lower() not in ("", "0", "false", "no")


def pytest_collection_modifyitems(config, items):
    """Skip device-only tests under the CA model instead of reporting them as failures.

    The simulator exposes no FFTS control address and no driver, so a test that
    needs either can only run on hardware; mark it `requires_device`.
    """
    if not _under_ca_model():
        return
    skip = pytest.mark.skip(reason="requires a real NPU device; the CA model does not provide it")
    for item in items:
        if "requires_device" in item.keywords:
            item.add_marker(skip)
