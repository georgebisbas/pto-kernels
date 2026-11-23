# Figure for `perf/cube-reduce-skip-empty-launch`

Image only, on an orphan branch so it renders in the pull-request description
without entering the diff. One Ascend 910B2, three arms rotated across six
repeats of 200 timed iterations after 50 warmup, input at a fixed address.

`fig1_result.png` — left: latency against input length, main against the
branch, with the one-tile threshold marked. Right: latency saved, next to the
same measurement made between main and a byte-identical rebuild of itself.
