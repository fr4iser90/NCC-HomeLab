# openai-whisper

Official OpenAI Whisper CLI (`pip install openai-whisper`).

```bash
docker network create ai-net
mkdir -p audio/out && cp clip.wav audio/audio.wav
docker compose build
docker compose run --rm openai-whisper /data/audio.wav --model tiny --output_dir /data/out
```

Prefer `faster-whisper` for speed on CPU; use this when you need the stock CLI.
