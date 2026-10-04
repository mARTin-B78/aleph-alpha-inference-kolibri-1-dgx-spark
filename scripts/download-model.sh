#!/usr/bin/env bash
# Download Aleph-Alpha/Kolibri-1 (~74 GB) to $MODEL_DIR. Needs the `hf` CLI (pip install -U huggingface_hub).
set -euo pipefail
: "${MODEL_DIR:?set MODEL_DIR, e.g. export MODEL_DIR=\$HOME/models/Aleph-Alpha/Kolibri-1}"
mkdir -p "$MODEL_DIR"
hf download Aleph-Alpha/Kolibri-1 --local-dir "$MODEL_DIR"
du -sh "$MODEL_DIR"
