# Figures for `perf/cube-reduce-int32-partials`

Images only, on their own orphan branch so they render in the pull-request
description without entering the diff. Generated 2026-11-23 on one Ascend
910B2 — three arms (main, a byte-identical rebuild of main as the noise floor,
and the branch) rotated across six repeats of 100 timed iterations, input held
at a fixed address.

| file | what it shows |
|---|---|
| `fig1_speedup.png` | Speedup by input length. int8 (int32 accumulator) is the only dtype that moves; float32 and float16 sit on the noise floor by construction. |
| `fig2_attribution.png` | The saving against the number of serialized 8-element vector operations removed, `blocks·S / 8` — the whole chain, since the column fold and the halving chain are both full-width. The predictor comes from the host tiling rule alone; the fit is 11.5 ns per operation, R² = 0.9981. |

Harness, raw CSVs and plot sources live in
`pypto-3.0-notes/pto-kernels/int32_partials_plots/`.

Measured against `main` at `21c484d`, i.e. on top of #300.

Earlier campaigns: `fold-chunk-figures` (#297), `tail-rows-figures` (#300).
