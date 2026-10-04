#!/usr/bin/env bash
# Chat + tool-call smoke test against a running server.
set -euo pipefail
BASE="${BASE:-http://127.0.0.1:${PORT:-8000}}"
curl -fsS "$BASE/health" && echo "health ok"
echo "--- chat"
curl -fsS "$BASE/v1/chat/completions" -H 'Content-Type: application/json' -d '{
  "model":"Kolibri-1","max_tokens":2048,
  "messages":[{"role":"user","content":"Say hello in German, one sentence."}]}' \
  | python3 -c 'import sys,json; m=json.load(sys.stdin)["choices"][0]["message"]; print("content:",m.get("content")); print("reasoning:",(m.get("reasoning") or "")[:200])'
echo "--- tool call"
curl -fsS "$BASE/v1/chat/completions" -H 'Content-Type: application/json' -d '{
  "model":"Kolibri-1","max_tokens":2048,"tool_choice":"auto",
  "messages":[{"role":"user","content":"What is the weather in Berlin?"}],
  "tools":[{"type":"function","function":{"name":"get_weather","description":"Get current weather for a city",
   "parameters":{"type":"object","properties":{"location":{"type":"string"}},"required":["location"]}}}]}' \
  | python3 -c 'import sys,json; m=json.load(sys.stdin)["choices"][0]["message"]; print(json.dumps(m.get("tool_calls"),indent=1))'
