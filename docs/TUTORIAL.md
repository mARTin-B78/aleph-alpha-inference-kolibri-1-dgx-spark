# Tutorial: Kolibri-1 on a DGX Spark

Status: the compose file was config-validated only; run arguments come from a tested launch (see the main [README](../README.md)).

## 1. Prepare
Free the GPU (the model needs most of the 128 GB): `nvidia-smi` and `docker ps` to see what is running. Do not stop containers that belong to others.
```bash
cp .env.example .env     # edit MODEL_DIR (absolute path); keep BIND_ADDR=127.0.0.1
```

## 2. Download the weights (~74 GB)
```bash
pip install -U huggingface_hub     # provides `hf`
export MODEL_DIR=/path/to/models/Aleph-Alpha/Kolibri-1
./scripts/download-model.sh
```
The model is public; a token is normally not required. If you hit rate limits, `export HF_TOKEN=...` in your shell (never in files).

## 3. Build the image
```bash
docker compose build
```
This adds `aleph-alpha-inference==1.0.0` to `vllm/vllm-openai:v0.29.0` (digest-pinned, arm64 variant is selected automatically).

## 4. Run
```bash
docker compose up -d
docker compose logs -f kolibri       # cold start takes 18-25 min
docker compose ps                    # STATUS becomes healthy
curl -fsS http://127.0.0.1:8000/health && echo ok
```

## 5. Test
```bash
./scripts/smoke-test.sh
```
Manual chat:
```bash
curl -s http://127.0.0.1:8000/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model":"Kolibri-1","max_tokens":2048,"messages":[{"role":"user","content":"Erkläre MoE in zwei Sätzen."}]}'
```
Tool call (OpenAI format): see the second request in `scripts/smoke-test.sh`; the answer arrives in `message.tool_calls`.

### Reasoning output
Thinking is on by default. The parser `kolibri1` returns it in `message.reasoning`; the answer is in `message.content`. If `max_tokens`
runs out during thinking, `content` is `null`, so give 2048+ tokens. Upstream documents `reasoning_effort` (none/low/medium/high) per request; the
`"none"` value was not tested here. Upstream-recommended sampling (model card): temperature 1.0, top_p 0.97, top_k 128.

## 6. Optional: llama-swap / LiteLLM
Generic placeholder snippets: [examples/llama-swap.yaml](../examples/llama-swap.yaml), [examples/litellm.yaml](../examples/litellm.yaml).
Set a long ready timeout (>= 1800 s) because of the load time.

## 7. Measure
```bash
uvx llama-benchy --base-url http://127.0.0.1:8000/v1 --model Kolibri-1 --pp 2048 --tg 128 --depth 0 16384 32768 --runs 2 --latency-mode generation
uvx tool-eval-bench --base-url http://127.0.0.1:8000 --model Kolibri-1 --short --parallel 2 --seed 42
```
Tools: [llama-benchy](https://github.com/eugr/llama-benchy), [tool-eval-bench](https://github.com/SeraphimSerapis/tool-eval-bench). Compare with [benchmarks/](../benchmarks/).

## 8. Stop, rollback, uninstall
```bash
docker compose stop            # stop, keep container
docker compose down            # remove container (weights on disk are untouched)
docker rmi vllm-kolibri:0.29.0-aai1.0.0   # remove image
rm -rf "$MODEL_DIR"            # delete weights (~74 GB), irreversible without re-download
```
Rollback: nothing else on the host is modified; to return to your previous setup just `docker compose down` and start the previous workload.
Nothing here uses volumes, so `down -v` loses nothing.
