# Figures for `perf/cube-reduce-fold-chunk`

Images only, kept on their own branch so they render in the pull-request
description without entering the diff. Generated 2026-11-20 on one Ascend
910B2. The harness, the raw CSV and these plots' sources live outside this
repository; the numbers they show are reproduced in the PR description.

## Cube-tail PR (`perf/cube-reduce-tail-rows`)

- `tailrows_fig1_speedup.png` — speedup by input length and dtype, against the
  noise floor of a byte-identical rebuild.
- `tailrows_fig2_attribution.png` — what the tail costs, with the tile count
  pinned at 64 and the tail length the only variable.
- `tailrows_fig3_{fp32,fp16,int8}_detail.png` — absolute latency at the worst
  ragged lengths, and the ragged-minus-aligned penalty itself.

Sources for all of them are in `pypto-3.0-notes/pto-kernels/tail_rows_plots/`.
