# llama-cpp

Docker-Setup für [llama.cpp](https://github.com/ggml-org/llama.cpp) im **Router Mode**: mehrere GGUF-Modelle per API wechseln, getrennte Services für Chat und Embeddings.

## Übersicht

| Service | Port | Config | Zweck |
|---|---|---|---|
| `llama-router` | `11535` | `models.ini` | Chat-LLMs (`/v1/chat/completions`) |
| `llama-embeddings` | `11536` | `models-embeddings.ini` | Embeddings (`/v1/embeddings`) |

Beide teilen sich `./models`, laufen aber als **eigene Container** — das Chat-LLM bleibt geladen, während Embeddings parallel für RAG genutzt werden können.

## Modell-Ordner

```
models/
├── llm/
│   ├── large/       # 30B+
│   ├── medium/
│   └── small/       # ≤4B, Code-LLMs
├── embeddings/
└── multimodal/      # VLM: Basis-.gguf + mmproj im gleichen Unterordner
```

Der Modellname in der API entspricht dem Sektionsnamen in der `.ini` (Dateiname ohne `.gguf`).

## Schnellstart

```bash
# 1. Ordner + Modelle (optional)
./model-dl.sh init-dirs
./model-dl.sh download          # fehlende Modelle aus models.ini

# 2. Starten (Vulkan / AMD Mesa)
docker compose up -d --build

# 3. Prüfen
curl http://localhost:11535/v1/models
curl http://localhost:11536/v1/models
```

## Backend: Vulkan vs ROCm

Zwei getrennte Builds — **nur eines gleichzeitig** (gleiche Ports, gleiche GPU).

| | Vulkan | ROCm |
|---|---|---|
| Compose | `compose.yaml` | `compose.rocm.yaml` |
| Dockerfile | `Dockerfile` (Source + `GGML_VULKAN`) | `Dockerfile.rocm` (Prebuilt Binary) |
| GPU | `/dev/dri`, `VK_ICD_FILENAMES` | `/dev/kfd` + `/dev/dri`, `HSA_OVERRIDE_GFX_VERSION` |
| Binary | `/workspace/llama.cpp/build/bin/llama-server` | `/app/llama-server` |

```bash
# Vulkan (Standard)
docker compose up -d --build

# ROCm (Alternative, oft schneller auf AMD)
docker compose down
docker compose -f compose.rocm.yaml up -d --build
```

`models.ini` und `models-embeddings.ini` sind für beide Backends identisch.

## Modelle herunterladen

`model-dl.sh` lädt GGUFs von Hugging Face und legt sie in die richtige Ordnerstruktur.

```bash
./model-dl.sh list                  # Status (present / missing)
./model-dl.sh download              # alle fehlenden Modelle aus den INIs
./model-dl.sh download Qwen         # einzelnes Modell (Teilname)
./model-dl.sh install-cli           # nur huggingface-cli installieren
```

Quellen stehen in `models.catalog.tsv` (Tab-getrennt: Dateiname, Unterordner, HF-Repo, optional abweichender Remote-Name).

```bash
# Optional: schnellere Downloads
pip install hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1

# Gated models
export HF_TOKEN=hf_...
```

## API-Nutzung

### Modelle auflisten

```bash
curl http://localhost:11535/v1/models
curl http://localhost:11536/v1/models
```

### Chat

```bash
curl http://localhost:11535/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen3.6-35B-A3B-MTP-UD-Q5_K_XL",
    "messages": [{"role": "user", "content": "Hallo"}]
  }'
```

### Embeddings

```bash
curl http://localhost:11536/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "bge-m3-Q4_K_M", "input": "Hello world"}'
```

### Modell wechseln / entladen

Beim LLM-Router wird bei `--models-max 1` das aktuelle Modell automatisch entladen, wenn ein anderes angefragt wird.

```bash
curl -X POST http://localhost:11535/v1/models/unload \
  -H "Content-Type: application/json" \
  -d '{"model": "Nemotron-3-Nano-30B-A3B-Q4_K_M"}'
```

## Neues Modell hinzufügen

1. GGUF in den passenden Ordner legen (z. B. `models/llm/small/`)
2. Sektion in `models.ini` oder `models-embeddings.ini` anlegen
3. Optional: Eintrag in `models.catalog.tsv` für HF-Download
4. `docker compose up -d` (INI wird neu gemountet)

Beispiel `models.ini`:

```ini
[Mein-Modell-Q4_K_M]
model = /models/llm/small/Mein-Modell-Q4_K_M.gguf
np = 2
c = 32768
b = 512
```

Für MTP-Modelle zusätzlich `spec-type = draft-mtp` und `spec-draft-n-max = 2`.

Embeddings in `models-embeddings.ini` — der Service startet mit `--embeddings`.

## Konfiguration

GPU-/Embedding-Flags stehen **pro Modell** in den INI-Dateien.

**Wichtig:** Keine Key-Value-Zeilen vor der ersten `[Sektion]` (z. B. kein `version = 1` oben) — llama.cpp ordnet das der Sektion `default` zu und listet sie in `/v1/models`.

- LLM: `ngl`, `fa`, `ctk`, `ctv` in jeder Sektion von `models.ini`
- Embeddings: `embeddings = true`, `ngl` in jeder Sektion von `models-embeddings.ini`
- `--models-max 1` am LLM-Router: nur ein großes Modell gleichzeitig im VRAM

Startmodell: `load-on-startup = true` in der gewünschten INI-Sektion.

## Dateien

| Datei | Beschreibung |
|---|---|
| `compose.yaml` | Vulkan-Stack (Router + Embeddings) |
| `compose.rocm.yaml` | ROCm-Stack (gleiche Struktur) |
| `Dockerfile` | llama.cpp Source-Build mit Vulkan |
| `Dockerfile.rocm` | Prebuilt ROCm-Binary (`lemonade-sdk/llamacpp-rocm`) |
| `models.ini` | Chat-Modelle und Presets |
| `models-embeddings.ini` | Embedding-Modelle |
| `models.catalog.tsv` | HF-Download-Quellen |
| `model-dl.sh` | Download-Skript (cross-distro) |

## Hinweise

- **Multimodal:** Basis-`.gguf` und `mmproj-*.gguf` in einen gemeinsamen Ordner (`models/multimodal/<name>/`). Beispiel in `models.ini` ist auskommentiert.
- **Geteilter Zugriff:** Clients nutzen Port `11535` für Chat, `11536` für Embeddings. Modellnamen exakt wie in der INI.
- **Logs:** `docker compose logs -f llama-router`
