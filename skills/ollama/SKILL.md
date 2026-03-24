---
name: ollama
description: Interact with local Ollama models running at localhost:11434. Chat, generate, list models, pull new ones. Available models: sociology-aih (custom sociology expert), llama3.2. Use when asked to query a local model, use sociology AI, or when cloud AI is unavailable.
---

# Ollama — Local LLM

Local model inference at `http://localhost:11434`. No API key needed. Available even when cloud AI is down.

**Available models:**
- `sociology-aih:latest` — Custom sociology/social theory expert (2GB)
- `llama3.2:latest` — General purpose (2GB)

---

## When This Skill Activates

**Explicit:** `/ollama`, "use ollama", "ask the local model"

**Intent detection:**
- "Ask the sociology model about X"
- "Use local AI for X"
- "Chat with llama about X"
- "Pull the [model] model"
- "What models do I have locally?"

---

## Setup Verification

```bash
curl -s http://localhost:11434/api/tags | python3 -c "
import sys,json; d=json.load(sys.stdin)
for m in d.get('models',[]): print(m['name'])
"
```

If not running: `ollama serve &` or check if the daemon is up.

---

## Quick Reference

| Task | Command |
|------|---------|
| List models | `curl -s http://localhost:11434/api/tags` |
| Chat (streaming) | `curl -s -X POST http://localhost:11434/api/chat -d '{...}'` |
| Generate (one-shot) | `curl -s -X POST http://localhost:11434/api/generate -d '{...}'` |
| Pull a model | `ollama pull <model>` |
| Show model info | `ollama show <model>` |
| Running models | `curl -s http://localhost:11434/api/ps` |

---

## Chat

### Single-turn chat (no streaming)
```bash
curl -s -X POST http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "sociology-aih:latest",
    "messages": [{"role": "user", "content": "What is Durkheim'\''s theory of social cohesion?"}],
    "stream": false
  }' | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(r['message']['content'])
"
```

### Multi-turn conversation
```bash
curl -s -X POST http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "sociology-aih:latest",
    "messages": [
      {"role": "system", "content": "You are a sociology research assistant."},
      {"role": "user", "content": "Explain social stratification."},
      {"role": "assistant", "content": "<prior response>"},
      {"role": "user", "content": "How does this relate to Bourdieu?"}
    ],
    "stream": false
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['message']['content'])"
```

### Use sociology-aih for domain-specific research
Best for:
- Social theory questions (Durkheim, Weber, Bourdieu, Giddens)
- Analyzing sociology paper abstracts
- Generating study questions from sociological concepts
- Classifying research into sociology subfields

```bash
curl -s -X POST http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d "{
    \"model\": \"sociology-aih:latest\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$QUESTION\"}],
    \"stream\": false
  }" | python3 -c "import sys,json; print(json.load(sys.stdin)['message']['content'])"
```

---

## Generate (one-shot completion)

```bash
curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama3.2:latest",
    "prompt": "Summarize the key ideas in social capital theory in 3 bullet points:",
    "stream": false
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])"
```

---

## Model Management

### List all local models
```bash
curl -s http://localhost:11434/api/tags | python3 -c "
import sys,json
for m in json.load(sys.stdin).get('models',[]):
    size_gb = m.get('size',0) / 1e9
    print(f'{m[\"name\"]:40s} {size_gb:.1f}GB  modified: {m.get(\"modified_at\",\"\")[:10]}')
"
```

### Pull a new model
```bash
ollama pull mistral:latest
ollama pull nomic-embed-text   # good for embeddings
ollama pull qwen2.5:7b
```

### Check what's currently loaded (GPU memory)
```bash
curl -s http://localhost:11434/api/ps | python3 -c "
import sys,json
for m in json.load(sys.stdin).get('models',[]):
    print(f'{m[\"name\"]} — {m.get(\"size_vram\",0)//1e9:.1f}GB VRAM')
"
```

### Delete a model
```bash
ollama rm <model-name>
```

---

## OpenAI-Compatible API

Ollama also exposes an OpenAI-compatible endpoint at `http://localhost:11434/v1` — useful for libraries that use the OpenAI SDK:

```python
from openai import OpenAI
client = OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")
response = client.chat.completions.create(
    model="sociology-aih:latest",
    messages=[{"role": "user", "content": "Explain symbolic interactionism"}]
)
print(response.choices[0].message.content)
```

---

## Notes

- Models stay loaded in memory for ~5 min after last use (configurable with `OLLAMA_KEEP_ALIVE`)
- sociology-aih is the custom fine-tuned model — prefer it for sociology domain tasks
- llama3.2 is good for general reasoning, summarization, code
- Streaming is off by default in examples above for easier parsing; set `"stream": true` for long responses
