# Figures for `perf/cube-reduce-tail-rows`

Images only, on their own orphan branch so they render in the pull-request
description without entering the diff. Generated 2026-11-20 on one Ascend
910B2 — three arms (main, a byte-identical rebuild of main as the noise floor,
and the branch) alternated across six repeats of 100 timed iterations, with
the input held at a fixed address.

| file | what it shows |
|---|---|
| `fig1_speedup.png` | Speedup by input length and dtype, all 225 configurations, against the noise floor. Filled circles are lengths whose tail has whole rows; open squares run main's code. |
| `fig2_attribution.png` | What the tail costs, with the tile count pinned at 64 and the tail length the only variable. Main climbs 39 ns per row (R² = 0.998); the branch is flat at 0.8 ns. |
| `fig3_fp32_detail.png` | float32: absolute latency at the five worst ragged lengths, and the ragged-minus-aligned penalty itself. |
| `fig3_fp16_detail.png` | The same for float16. |
| `fig3_int8_detail.png` | The same for int8. |

The harness, the raw CSVs and these plots' sources live outside this
repository, in `pypto-3.0-notes/pto-kernels/tail_rows_plots/`. Every number
they show is reproduced in the PR description.

The previous campaign's figures are on `fold-chunk-figures` (PR #297).
