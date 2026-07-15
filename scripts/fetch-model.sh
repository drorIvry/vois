#!/bin/bash
# Fetch Kokoro model weights + voice pack into Models/Kokoro (~340MB total).
# Build-time only — the app itself never touches the network.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p Models/Kokoro

fetch() {  # url dest expected_min_bytes
  if [ -f "$2" ] && [ "$(stat -f%z "$2")" -ge "$3" ]; then
    echo "have $2"
    return
  fi
  echo "fetching $2 ..."
  curl -fL --progress-bar -o "$2" "$1"
}

fetch "https://huggingface.co/prince-canuma/Kokoro-82M/resolve/main/kokoro-v1_0.safetensors" \
      Models/Kokoro/kokoro-v1_0.f32.safetensors 300000000

# Cast f32 -> bf16: halves the bundled model (327MB -> 164MB) and warm RSS
# (542MB -> ~350MB, under the 400MB PRD target). Needs python mlx (uv fallback).
if [ ! -f Models/Kokoro/kokoro-v1_0.safetensors ] || \
   [ "$(stat -f%z Models/Kokoro/kokoro-v1_0.safetensors)" -gt 200000000 ]; then
  PY="python3"
  python3 -c "import mlx.core" 2>/dev/null || PY="uv run --with mlx python3"
  $PY - <<'EOF'
import mlx.core as mx
w = mx.load("Models/Kokoro/kokoro-v1_0.f32.safetensors")
mx.save_safetensors(
    "Models/Kokoro/kokoro-v1_0.safetensors",
    {k: (v.astype(mx.bfloat16) if v.dtype == mx.float32 else v) for k, v in w.items()})
print("converted to bf16")
EOF
fi

# Curated English voices (keep in sync with KokoroVoices.swift).
mkdir -p Models/Kokoro/voices
for v in af_heart af_bella af_nicole af_sarah af_sky am_adam am_michael bf_emma bf_isabella bm_george bm_lewis; do
  fetch "https://huggingface.co/prince-canuma/Kokoro-82M/resolve/main/voices/$v.safetensors" \
        "Models/Kokoro/voices/$v.safetensors" 500000
done
rm -f Models/Kokoro/voices.npz

echo "done:"
ls -lh Models/Kokoro
