# whisper.cpp

Native C++ Whisper (CPU). Portable on x86_64 and aarch64.

```bash
docker network create ai-net
mkdir -p audio models
wget -O models/ggml-tiny.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin
cp clip.wav audio/audio.wav
docker compose build
docker compose run --rm whisper-cpp -m /models/ggml-tiny.bin /data/audio.wav
```
