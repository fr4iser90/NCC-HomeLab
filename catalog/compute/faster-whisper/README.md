# faster-whisper

CTranslate2 Whisper CLI. Arch-neutral image (x86_64 / aarch64).

```bash
docker network create ai-net   # once
mkdir -p audio && cp clip.wav audio/audio.wav
docker compose build
docker compose run --rm faster-whisper
docker compose run --rm faster-whisper /data/clip.wav --model base
```

GPU (Jetson CDI): uncomment `devices` / `environment` in `compose.yaml`, then add `--device cuda --compute-type float16`.
