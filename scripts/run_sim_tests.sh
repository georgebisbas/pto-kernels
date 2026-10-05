#!/usr/bin/env bash
# --------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# All rights reserved.
# See LICENSE in the root of the software repository:
# https://github.com/huawei-csl/pto-kernels/
# for the full License text.
# --------------------------------------------------------------------------------
#
# Run pytest against the CANN CA model (no NPU required).
#
#   scripts/run_sim_tests.sh                          # whole tests/ tree, batched
#   scripts/run_sim_tests.sh tests/test_abs.py        # one file
#   BATCH_SIZE=0 scripts/run_sim_tests.sh tests/      # everything in one msprof run
#
# Simulator state does not reliably survive a long test sequence, and msprof's
# own --timeout terminates a run whose slowest case exceeds it; either way the
# cases that would have passed after that point are lost, which looks like a
# kernel failure but is not. Every batch below therefore gets its own
# `msprof op simulator` process, so a stall only costs the batch that hits it.
#
# Environment:
#   ASCEND_HOME_PATH / ASCEND_TOOLKIT_HOME  CANN install (required)
#   NPU_DEVICE         device string (default npu:0; a bare index is rejected)
#   BATCH_SIZE         test ids per msprof run (default 8; 0 = a single run)
#   BUDGET             wall seconds per batch (default 900)
#   MSPROF_TIMEOUT     msprof --timeout (default BUDGET - 60)
#   MSPROF_SOC_VERSION CA-model target (default Ascend910B2)
#   KEEP_SIM_OUT       keep the msprof output tree (default 0)
#
# Exit status: 0 when every batch passed, 1 when a batch failed or hit its budget.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASCEND_HOME_PATH="${ASCEND_HOME_PATH:-${ASCEND_TOOLKIT_HOME:-}}"
SOC_VERSION="${MSPROF_SOC_VERSION:-Ascend910B2}"
NPU_DEVICE="${NPU_DEVICE:-npu:0}"
BATCH_SIZE="${BATCH_SIZE:-8}"
BUDGET="${BUDGET:-900}"
MSPROF_TIMEOUT="${MSPROF_TIMEOUT:-$((BUDGET - 60))}"
TARGETS=("$@")
if ((${#TARGETS[@]} == 0)); then
  TARGETS=(tests/)
fi

die() {
  echo "ERROR: $*" >&2
  exit 2
}

[[ -n "${ASCEND_HOME_PATH}" ]] || die "set ASCEND_HOME_PATH (or ASCEND_TOOLKIT_HOME) to a CANN install"
[[ -d "${ASCEND_HOME_PATH}/tools/simulator/${SOC_VERSION}/lib" ]] ||
  die "no CA model at ${ASCEND_HOME_PATH}/tools/simulator/${SOC_VERSION}"
command -v msprof >/dev/null ||
  die "msprof not on PATH — source ${ASCEND_HOME_PATH}/bin/setenv.bash first"

export PTO_SIMULATOR=1
export NPU_DEVICE
export LD_LIBRARY_PATH="${ASCEND_HOME_PATH}/tools/simulator/${SOC_VERSION}/lib:${LD_LIBRARY_PATH:-}"

OUT_DIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_SIM_OUT:-0}" != "1" ]]; then
    rm -rf "${OUT_DIR}"
  else
    echo "msprof output kept in ${OUT_DIR}"
  fi
}
trap cleanup EXIT

# msprof re-splits the command after its own options, so every pytest argument
# below must be a single whitespace-free token (node ids qualify; a quoted
# `-k "a and b"` expression does not).
sim_pytest() { # <label> <pytest args...>
  local label="$1"
  shift
  timeout "${BUDGET}" msprof op simulator \
    --soc-version="${SOC_VERSION}" \
    --timeout="${MSPROF_TIMEOUT}" \
    --output="${OUT_DIR}/${label}" \
    python3 -m pytest "$@" >"${OUT_DIR}/${label}.log" 2>&1
}

collect_ids() { # <path> -> one test id per line
  local path="$1"
  sim_pytest "collect_$(basename "${path}" .py)" "${path}" --collect-only -q || true
  grep -a '::' "${OUT_DIR}/collect_$(basename "${path}" .py).log" | sed 's/[[:space:]]*$//'
}

cd "${REPO_DIR}"

printf 'CA model %s · device %s · batch size %s · budget %ss\n\n' \
  "${SOC_VERSION}" "${NPU_DEVICE}" "${BATCH_SIZE}" "${BUDGET}"

total_batches=0
failed_batches=0
capped_batches=0

for target in "${TARGETS[@]}"; do
  if [[ -f "${target}" ]]; then
    mapfile -t ids < <(collect_ids "${target}")
  else
    ids=("${target}") # an explicit node id
  fi

  if ((${#ids[@]} == 0)); then
    printf '%-52s %s\n' "${target}" "FAIL (no tests collected)"
    failed_batches=$((failed_batches + 1))
    continue
  fi

  take="${BATCH_SIZE}"
  ((take == 0)) && take="${#ids[@]}"

  batch=1
  i=0
  while ((i < ${#ids[@]})); do
    chunk=()
    for ((j = 0; j < take && i + j < ${#ids[@]}; j++)); do
      chunk+=("${ids[$((i + j))]}")
    done
    i=$((i + ${#chunk[@]}))

    label="$(basename "${target}" .py)_b${batch}"
    rc=0
    sim_pytest "${label}" -q "${chunk[@]}" || rc=$?
    summary="$(grep -aoE '[0-9]+ (passed|failed|error|skipped)[^=]*' "${OUT_DIR}/${label}.log" | tail -1 || true)"
    case "${rc}" in
      0) status="PASS ${summary}" ;;
      124)
        status="CAPPED after ${BUDGET}s ${summary}"
        capped_batches=$((capped_batches + 1))
        ;;
      *)
        status="FAIL rc=${rc} ${summary}"
        failed_batches=$((failed_batches + 1))
        ;;
    esac
    printf '%-52s %s\n' "${target} [${#chunk[@]} cases, batch ${batch}]" "${status}"
    batch=$((batch + 1))
    total_batches=$((total_batches + 1))
  done
done

printf '\n%d batches · %d failed · %d capped\n' \
  "${total_batches}" "${failed_batches}" "${capped_batches}"
((failed_batches == 0 && capped_batches == 0))
