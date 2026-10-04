# Kolibri-1 on the NVIDIA DGX Spark (GB10)

Minimal, standalone recipe to serve [Aleph-Alpha/Kolibri-1](https://huggingface.co/Aleph-Alpha/Kolibri-1)
(78B-parameter FP8 Mixture-of-Experts, about 3.5B active per token, Apache-2.0) with vLLM on a DGX Spark
(GB10, arm64, CUDA 13), plus measured numbers and the gotchas.

Why this repo: the upstream [aleph-alpha-inference](https://github.com/Aleph-Alpha/aleph-alpha-inference) container image is amd64-only
(per the upstream project; verify yourself), and the Spark is arm64. The plugin itself is pure Python, so the `Dockerfile` here
adds it to the multi-arch `vllm/vllm-openai:v0.29.0` image.

> **Status / honesty note.** The run arguments come from a launch that worked on a real DGX Spark (llama-swap launcher, arguments
> verified with `docker inspect` of the running container). The `docker-compose.yml` in this repo re-expresses those arguments and was
> **config-validated only** (`docker compose config -q`); it was not run end-to-end because the GPU was busy. The `Dockerfile` was not
> rebuilt for publication; it is identical to the one used for the tested image except for the added base-image digest pin.
> Please open an issue with your results or problems.

## Requirements
- NVIDIA DGX Spark (GB10, 128 GB unified memory), about 100 GiB or more of free unified memory (weights 73.5 GiB plus runtime; stop other models first)
- About 75 GB disk for the weights, plus the image
- Docker with the NVIDIA container toolkit (`docker run --gpus all` works)
- Hugging Face CLI (`hf`) for the download

## Quick start
```bash
git clone https://github.com/mARTin-B78/aleph-alpha-inference-kolibri-1-dgx-spark.git && cd aleph-alpha-inference-kolibri-1-dgx-spark
cp .env.example .env && $EDITOR .env          # set MODEL_DIR
export $(grep '^MODEL_DIR=' .env)             # for the download script
./scripts/download-model.sh                   # ~74 GB
docker compose up -d --build                  # ready after ~20-25 min, see: docker compose logs -f
./scripts/smoke-test.sh                       # health, chat, tool call
```
Full walkthrough: [docs/TUTORIAL.md](docs/TUTORIAL.md).

## Settings
| Setting | Value | Why |
|---|---|---|
| `--gpu-memory-utilization` | 0.78 | Highest value that worked on GB10; the usable CUDA memory is lower than MemAvailable (about 11 GiB gap observed here). Higher risks a host crash. A launcher picked values 0.68-0.78 automatically; 0.78 was effective. |
| `--max-model-len` | 131072 | Half of the native 262k; KV cache is small (4 KV heads, sliding window), so more is probably possible but untested here. |
| `--max-num-seqs` | 4 | Interactive/agent use; memory headroom. |
| `--kv-cache-dtype` | fp8 | Upstream serve example. |
| `--enable-prefix-caching` | on | Agent loops resend long prefixes. |
| `--reasoning-parser` / `--tool-call-parser` | `kolibri1` | From the plugin (tool parser is Hermes2Pro-style). |
| `--enable-auto-tool-choice` | on | Needed for OpenAI-style tool calls. |
| `ipc: host` | | As in the tested run. |
| `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`, `OMP_NUM_THREADS=4` | | As in the tested run; effect not isolated. |

Differences from the tested run: tested container used `--network host` and a read-write model mount; compose uses a published port
(127.0.0.1 only by default) and a read-only mount (untested, should be fine).

## Results (one DGX Spark, vLLM 0.29.0, CUDA 13.0, aleph-alpha-inference 1.0.0)
| Context depth | Prefill tok/s | Decode tok/s | TTFT |
|---|---|---|---|
| 0 | 1402 | 20.4 | 1.5 s |
| 16k | 1331 | 19.9 | 12.3 s |
| 32k | 1131 | 19.6 | 27.3 s |

llama-benchy, pp2048/tg128, 2 runs, concurrency 1. Tool-calling (tool-eval-bench, short mode, 15 scenarios): 100/100, 15/15 passed,
all 5 categories 6/6; Deployability 74, Responsiveness 15 (median turn 9.6 s with thinking on). A direct `get_weather` Berlin tool-call probe worked.
Weights 73.5 GiB; cold load 18-25 min. Raw data and methodology: [benchmarks/](benchmarks/).

Caveats: single hardware sample, small run counts, `--parallel 2` in the tool eval can add timing noise, the 15-scenario subset is saturated,
and no before/after tuning was done, so these are not tuning claims.

## Known issues
- **Load takes 18-25 min** (weight load alone about 1087 s). Not a page-cache first-read effect. Cause unverified; my guess is CPU/unified-memory-bound FP8 MoE weight processing. Compose healthcheck therefore has a 30 min start period.
- **Decode is about 20 tok/s**: with 73 GiB of weights on the Spark's memory bandwidth, that is expected; only about 3.5B parameters are active, but it is still bandwidth/overhead bound.
- **Thinking is on by default.** The reasoning parser puts it in `reasoning` and `content` can be `null` if `max_tokens` is exhausted while thinking: use generous `max_tokens`, or send `reasoning_effort: "none"` (per upstream docs; not tested here).
- One-time Triton `fused_moe` JIT spike on first long request.
- Cannot coexist with other large models on 128 GB.
- The API has no authentication; keep it on localhost or put a gateway in front.

## Troubleshooting
- `docker compose logs -f kolibri`; wait for "Application startup complete" / `/health` returning 200.
- Out-of-memory at start: stop other GPU workloads, lower `GMEM` (e.g. 0.70) and/or `MAX_MODEL_LEN`.
- Plugin not found / parser `kolibri1` unknown: check `docker run --rm --entrypoint pip vllm-kolibri:0.29.0-aai1.0.0 show aleph-alpha-inference`.
- Build resolves a different vLLM: the plugin needs `vllm>=0.29,<0.30`; `pip check` output is shown in the build log (build does not fail on it).

## License
Files in this repo: Apache-2.0 ([LICENSE](LICENSE)). The Kolibri-1 weights (Apache-2.0 per the model card), vLLM, the
aleph-alpha-inference plugin (Apache-2.0 per its repo) and the base image keep their own licenses; check them before redistributing.
The model is downloaded directly from Hugging Face; nothing is sent to third parties by this repo's scripts.

## Links and credit
- Model: https://huggingface.co/Aleph-Alpha/Kolibri-1 , announcement: https://aleph-alpha.com/en/blog/kolibri-has-landed-a-sovereign-open-weight-model/
- Plugin: https://github.com/Aleph-Alpha/aleph-alpha-inference
- vLLM: https://github.com/vllm-project/vllm
- llama-benchy: https://github.com/eugr/llama-benchy , tool-eval-bench: https://github.com/SeraphimSerapis/tool-eval-bench

## Disclaimer
Unofficial community recipe, not affiliated with Aleph Alpha or NVIDIA. Provided as is, without warranty. Verify settings
(especially GPU memory utilization) on your own system; a too-high value can hang or crash a unified-memory machine.
