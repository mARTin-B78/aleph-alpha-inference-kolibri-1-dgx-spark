# llama-benchy raw results (Kolibri-1, DGX Spark GB10)

Date 2026-10-04, llama-benchy 0.4.1.dev1, `--latency-mode generation`, 2 runs per cell, 1 warmup, concurrency 1.
Mean ± std as printed by the tool. Average generation latency probe: 159.6 ms.

| model     |            test |             t/s |     peak t/s |         ttfr (ms) |      est_ppt (ms) |     e2e_ttft (ms) |
|:----------|----------------:|----------------:|-------------:|------------------:|------------------:|------------------:|
| Kolibri-1 |          pp2048 | 1401.90 ± 61.52 |              |   1452.97 ± 27.15 |   1293.37 ± 27.15 |   1454.08 ± 26.04 |
| Kolibri-1 |           tg128 |    20.44 ± 0.01 | 22.50 ± 0.50 |                   |                   |                   |
| Kolibri-1 | pp2048 @ d16384 |  1331.43 ± 9.80 |              | 12341.88 ± 142.59 | 12182.28 ± 142.59 | 12350.68 ± 136.42 |
| Kolibri-1 |  tg128 @ d16384 |    19.94 ± 0.01 | 21.00 ± 0.00 |                   |                   |                   |
| Kolibri-1 | pp2048 @ d32768 |  1131.23 ± 5.68 |              | 27271.09 ± 396.05 | 27111.50 ± 396.05 | 27292.75 ± 394.86 |
| Kolibri-1 |  tg128 @ d32768 |    19.62 ± 0.12 | 21.00 ± 0.00 |                   |                   |                   |

Notes: the tokenizer fell back to the `gpt2` approximation (HF tokenizer not fetched by the tool), so token counts are approximate.
The first long-context run included a one-time Triton fused_moe JIT spike (excluded here by the warmup run).
