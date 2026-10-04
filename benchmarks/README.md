# Benchmarks

Single hardware sample: one NVIDIA DGX Spark (GB10, 128 GB unified memory), vLLM 0.29.0, CUDA 13.0,
aleph-alpha-inference 1.0.0, settings as in `docker-compose.yml` (`MAX_MODEL_LEN=131072`, `MAX_NUM_SEQS=4`,
`--kv-cache-dtype fp8`, prefix caching, `--gpu-memory-utilization` between 0.68 and 0.78 chosen by the launcher; final effective value 0.78).
These are measurements, not tuning claims: nothing was compared before/after.

## Throughput (llama-benchy)
- Files: `llama-benchy-results.md` (raw table), `llama-benchy-results.csv`.
- Command (tool: https://github.com/eugr/llama-benchy):
  `uvx llama-benchy --base-url http://127.0.0.1:8000/v1 --model Kolibri-1 --pp 2048 --tg 128 --depth 0 16384 32768 --runs 2 --latency-mode generation`
  (The original run was driven by a wrapper script with the same pp/tg/depth/runs settings.)
- Caveats: 2 runs only; tokenizer fell back to a gpt2 approximation.

## Tool-calling quality (tool-eval-bench)
- File: `tool-eval-bench-short.md` (v2.7.0, "short" mode, 15 scenarios, `--parallel 2`, seed 42, temperature 0, thinking enabled, max tokens 16384, 232.7 s).
- Result: 100/100, 15/15 scenarios, all 5 categories 6/6. Deployability 74, Responsiveness 15 (median turn 9.6 s, because thinking is on by default).
- Tool: https://github.com/SeraphimSerapis/tool-eval-bench, run with `uvx tool-eval-bench --base-url http://127.0.0.1:8000 --model Kolibri-1 --short --parallel 2 --seed 42 --temperature 0` (flags per `--help`; the original used a wrapper, so the exact invocation may differ slightly).
- Caveats: the 15-scenario subset is small and saturating; `--parallel 2` can add timing noise; scenarios use synthetic tools; host name in the report is generic.

## Load time
18-25 min per cold start (weight load ~1087 s of it; one measured full ready time 1448 s via llama-swap).
The cause is unverified (guess: CPU/unified-memory-bound FP8 MoE weight processing); it was not a page-cache first-read effect.
