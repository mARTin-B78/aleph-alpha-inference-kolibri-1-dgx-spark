# Kolibri-1 (Aleph Alpha) on DGX Spark GB10 (arm64, CUDA 13).
# The official aleph-alpha-inference container image is amd64-only. This adds the
# pure-Python vLLM plugin (needs vllm>=0.29,<0.30) onto the upstream multi-arch vLLM image.
# Base is pinned by tag AND by multi-arch index digest (resolved 2026-10-04).
FROM vllm/vllm-openai:v0.29.0@sha256:c2914767605584b6d8f45686b82de173ecc99e781897aa3d0a66dacd72c51ae1
RUN pip install --no-cache-dir "aleph-alpha-inference==1.0.0" \
 && pip check || true
