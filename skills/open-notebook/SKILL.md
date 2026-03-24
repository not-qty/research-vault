---
name: open-notebook
description: Complete API for Open Notebook — self-hosted, private NotebookLM alternative running at localhost:5055. Create notebooks, add sources (URLs, text, files), chat with content, generate podcasts, run transformations, take notes, and search across everything. Activates on explicit /open-notebook or intent like "add this to my notebook", "generate a podcast from X", "ask my notebook about Y".
---

# Open Notebook

Self-hosted, privacy-first research assistant. Full programmatic access via REST API at `http://localhost:5055`. No authentication required — local only.

**Web UI:** http://localhost:8502
**API docs:** http://localhost:5055/docs
**Version:** 1.8.1

---

## Setup Verification

Before running any workflow, verify the service is up:

```bash
curl -s http://localhost:5055/health
# Expected: {"status":"healthy"}
```

If not healthy:
```bash
cd ~/work/open-notebook && docker compose up -d
sleep 5 && curl -s http://localhost:5055/health
```

Set the base URL once at the top of any session:
```bash
ON="http://localhost:5055"
```

---

## When This Skill Activates

**Explicit:** User says `/open-notebook`, "use open-notebook", "use my local notebook"

**Intent detection:**
- "Add this URL/article/file to my notebook"
- "Create a notebook about X"
- "Ask my notebook about X"
- "Search my research for X"
- "Generate a podcast from my notebook"
- "Summarize / get key insights from X"
- "Save this as a note"
- "Transform this text"
- "What have I saved about X?"

---

## Autonomy Rules

**Run automatically (no confirmation):**
- Health check
- List notebooks / sources / notes
- Get notebook or source details
- Create notebook
- Add source (URL or text)
- Create note
- Check source processing status
- List transformations / episode profiles
- Chat (read-only questions)
- Search/ask

**Ask before running:**
- Delete notebook / source / note (destructive)
- Generate podcast (long-running, uses AI credits)
- Execute transformation (modifies/generates content)
- Rebuild embeddings (long-running)
- Retry failed source

---

## Quick Reference

```bash
ON="http://localhost:5055"
```

| Task | Command |
|------|---------|
| Health check | `curl -s $ON/health` |
| List notebooks | `curl -s $ON/api/notebooks` |
| Create notebook | `curl -s -X POST $ON/api/notebooks -H 'Content-Type: application/json' -d '{"name":"Title"}'` |
| Get notebook | `curl -s $ON/api/notebooks/<id>` |
| Delete notebook | `curl -s -X DELETE $ON/api/notebooks/<id>` |
| List sources | `curl -s $ON/api/sources` |
| Add URL source | See Sources section |
| Add text source | See Sources section |
| Check source status | `curl -s $ON/api/sources/<id>/status` |
| Get source insights | `curl -s $ON/api/sources/<id>/insights` |
| Generate insights | See Insights section |
| List notes | `curl -s $ON/api/notes` |
| Create note | See Notes section |
| Create chat session | See Chat section |
| Send chat message | See Chat section |
| Search/ask | See Search section |
| List transformations | `curl -s $ON/api/transformations` |
| Run transformation | See Transformations section |
| Generate podcast | See Podcasts section |
| Check podcast job | `curl -s $ON/api/podcasts/jobs/<job_id>` |
| List episodes | `curl -s $ON/api/podcasts/episodes` |
| Get models | `curl -s $ON/api/models` |
| Get default models | `curl -s $ON/api/models/defaults` |

---

## Notebooks

### List all notebooks
```bash
curl -s $ON/api/notebooks | python3 -c "
import sys, json
notebooks = json.load(sys.stdin)
for nb in notebooks:
    print(f'{nb[\"id\"]}: {nb[\"name\"]}')
"
```

### Create notebook
```bash
NB=$(curl -s -X POST $ON/api/notebooks \
  -H 'Content-Type: application/json' \
  -d '{"name": "My Research Topic", "description": "Optional description"}')
NB_ID=$(echo $NB | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Created: $NB_ID"
```

### Get notebook details
```bash
curl -s $ON/api/notebooks/$NB_ID | python3 -c "
import sys, json
nb = json.load(sys.stdin)
print(f'Name: {nb[\"name\"]}')
print(f'Description: {nb.get(\"description\",\"\")}')
print(f'Sources: {len(nb.get(\"sources\",[]))}')
"
```

### Update notebook
```bash
curl -s -X PUT $ON/api/notebooks/$NB_ID \
  -H 'Content-Type: application/json' \
  -d '{"name": "New Name", "description": "Updated description"}'
```

### Delete notebook
```bash
curl -s -X DELETE $ON/api/notebooks/$NB_ID
```

### Attach existing source to notebook
```bash
curl -s -X POST $ON/api/notebooks/$NB_ID/sources/$SOURCE_ID
```

---

## Sources

Sources are the content Open Notebook learns from. Each source is processed and embedded for search and chat.

### Add a URL source
```bash
SOURCE=$(curl -s -X POST $ON/api/sources \
  -H 'Content-Type: application/json' \
  -d "{
    \"type\": \"url\",
    \"url\": \"https://example.com/article\",
    \"notebook_id\": \"$NB_ID\",
    \"async_processing\": \"true\"
  }")
SOURCE_ID=$(echo $SOURCE | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Source ID: $SOURCE_ID"
```

### Add a YouTube video as source
```bash
SOURCE=$(curl -s -X POST $ON/api/sources \
  -H 'Content-Type: application/json' \
  -d "{
    \"type\": \"url\",
    \"url\": \"https://www.youtube.com/watch?v=VIDEO_ID\",
    \"notebook_id\": \"$NB_ID\",
    \"async_processing\": \"true\"
  }")
```

### Add text/paste as source
```bash
curl -s -X POST $ON/api/sources \
  -H 'Content-Type: application/json' \
  -d "{
    \"type\": \"text\",
    \"content\": \"Paste your text content here...\",
    \"title\": \"My Text Source\",
    \"notebook_id\": \"$NB_ID\"
  }"
```

### Add a file source
```bash
curl -s -X POST $ON/api/sources \
  -F "type=file" \
  -F "notebook_id=$NB_ID" \
  -F "file=@/path/to/document.pdf"
```

### Check source processing status
```bash
curl -s $ON/api/sources/$SOURCE_ID/status | python3 -c "
import sys, json
s = json.load(sys.stdin)
print(f'Status: {s[\"status\"]}')
print(f'Message: {s[\"message\"]}')
"
```

**Wait for source to be ready:**
```bash
while true; do
  STATUS=$(curl -s $ON/api/sources/$SOURCE_ID/status | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
  echo "Status: $STATUS"
  if [ "$STATUS" = "complete" ] || [ "$STATUS" = "error" ]; then break; fi
  sleep 5
done
```

### List all sources
```bash
curl -s $ON/api/sources | python3 -c "
import sys, json
sources = json.load(sys.stdin)
for s in sources:
    print(f'{s[\"id\"]}: {s.get(\"title\",\"Untitled\")} [{s.get(\"status\",\"\")}]')
"
```

### Delete source
```bash
curl -s -X DELETE $ON/api/sources/$SOURCE_ID
```

---

## Insights

Insights are AI-generated analysis of a source (key points, summary, topics).

### Get existing insights for a source
```bash
curl -s $ON/api/sources/$SOURCE_ID/insights | python3 -c "
import sys, json
insights = json.load(sys.stdin)
for i in insights:
    print(f'[{i[\"id\"]}] {i.get(\"title\",\"\")}')
    print(i.get('content',''))
    print()
"
```

### Generate new insight
```bash
curl -s -X POST $ON/api/sources/$SOURCE_ID/insights \
  -H 'Content-Type: application/json' \
  -d '{"transformation_id": "transformation:91k9npful3eaen8tjq5o"}'
# transformation:91k9npful3eaen8tjq5o = Key Insights
# transformation:2dkji8r5vm94uo5rci8t = Dense Summary
# transformation:52of6lkncba54509o2ak = Simple Summary
```

### Save insight as note
```bash
curl -s -X POST $ON/api/insights/$INSIGHT_ID/save-as-note \
  -H 'Content-Type: application/json' \
  -d "{\"notebook_id\": \"$NB_ID\"}"
```

---

## Chat

### Create a chat session
```bash
SESSION=$(curl -s -X POST $ON/api/chat/sessions \
  -H 'Content-Type: application/json' \
  -d '{"title": "Research Chat"}')
SESSION_ID=$(echo $SESSION | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Session: $SESSION_ID"
```

### Send a message (notebook-scoped)
```bash
RESPONSE=$(curl -s -X POST $ON/api/chat/execute \
  -H 'Content-Type: application/json' \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"message\": \"What are the main themes across my sources?\",
    \"context\": {\"notebook_id\": \"$NB_ID\"}
  }")
echo $RESPONSE | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(r.get('response', r.get('content', r)))
"
```

### Send a message (global, no notebook filter)
```bash
curl -s -X POST $ON/api/chat/execute \
  -H 'Content-Type: application/json' \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"message\": \"Your question here\",
    \"context\": {}
  }"
```

### List sessions
```bash
curl -s $ON/api/chat/sessions | python3 -c "
import sys, json
sessions = json.load(sys.stdin)
for s in sessions:
    print(f'{s[\"id\"]}: {s.get(\"title\",\"Untitled\")}')
"
```

---

## Notes

### Create a note
```bash
curl -s -X POST $ON/api/notes \
  -H 'Content-Type: application/json' \
  -d "{
    \"title\": \"My Note Title\",
    \"content\": \"## Summary\n\nNote content here...\",
    \"notebook_id\": \"$NB_ID\"
  }"
```

### List all notes
```bash
curl -s $ON/api/notes | python3 -c "
import sys, json
notes = json.load(sys.stdin)
for n in notes:
    print(f'{n[\"id\"]}: {n.get(\"title\",\"Untitled\")}')
"
```

### Update a note
```bash
curl -s -X PUT $ON/api/notes/$NOTE_ID \
  -H 'Content-Type: application/json' \
  -d '{"content": "Updated content here..."}'
```

### Save to Obsidian vault
After getting note content, save it to the research vault:
```bash
NOTE_CONTENT=$(curl -s $ON/api/notes/$NOTE_ID | python3 -c "import sys,json; n=json.load(sys.stdin); print(n.get('content',''))")
echo "$NOTE_CONTENT" > ~/work/research-vault/Research/$(date +%Y-%m-%d)-note-title.md
```

---

## Search / Ask

Cross-notebook semantic search. Requires default models to be configured in Open Notebook settings.

### Ask a question across all content
```bash
# First get default models
DEFAULTS=$(curl -s $ON/api/models/defaults)
CHAT_MODEL=$(echo $DEFAULTS | python3 -c "import sys,json; print(json.load(sys.stdin).get('default_chat_model',''))")

curl -s -X POST $ON/api/search/ask \
  -H 'Content-Type: application/json' \
  -d "{
    \"question\": \"What are the key themes in my research?\",
    \"strategy_model\": \"$CHAT_MODEL\",
    \"answer_model\": \"$CHAT_MODEL\",
    \"final_answer_model\": \"$CHAT_MODEL\"
  }" | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(r.get('answer', json.dumps(r, indent=2)))
"
```

---

## Transformations

Transformations apply AI analysis to text. Built-in transformations:

| ID | Name |
|----|------|
| `transformation:zz1291x7cak8leov6w22` | Paper Analysis |
| `transformation:2dkji8r5vm94uo5rci8t` | Dense Summary |
| `transformation:91k9npful3eaen8tjq5o` | Key Insights |
| `transformation:7alaw5n2p7x036j2w80p` | Reflection Questions |
| `transformation:52of6lkncba54509o2ak` | Simple Summary |
| `transformation:mdkftnue4n52zi2ci12v` | Table of Contents |

### List all transformations
```bash
curl -s $ON/api/transformations | python3 -c "
import sys, json
ts = json.load(sys.stdin)
for t in ts:
    print(f'{t[\"id\"]}: {t[\"title\"]}')
"
```

### Execute a transformation
```bash
# Get default transformation model
MODEL=$(curl -s $ON/api/models/defaults | python3 -c "
import sys, json; d=json.load(sys.stdin)
print(d.get('default_transformation_model') or d.get('default_chat_model',''))
")

curl -s -X POST $ON/api/transformations/execute \
  -H 'Content-Type: application/json' \
  -d "{
    \"transformation_id\": \"transformation:91k9npful3eaen8tjq5o\",
    \"input_text\": \"Paste text to transform here...\",
    \"model_id\": \"$MODEL\"
  }" | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(r.get('output', r.get('result', json.dumps(r, indent=2))))
"
```

---

## Podcasts

Generate audio podcast episodes from notebook content.

### Episode profiles available:
| Name | Description |
|------|-------------|
| `business_analysis` | Business-focused analysis and discussion |
| `solo_expert` | Single expert explaining complex topics |
| `tech_discussion` | Technical discussion between 2 experts |

### Speaker profiles available:
| Name | Description |
|------|-------------|
| `business_panel` | Business analysis panel |
| `solo_expert` | Single expert for educational content |
| `tech_experts` | Two technical experts |

### Generate a podcast
```bash
JOB=$(curl -s -X POST $ON/api/podcasts/generate \
  -H 'Content-Type: application/json' \
  -d "{
    \"episode_profile\": \"tech_discussion\",
    \"speaker_profile\": \"tech_experts\",
    \"episode_name\": \"My Research Episode\",
    \"notebook_id\": \"$NB_ID\"
  }")
JOB_ID=$(echo $JOB | python3 -c "import sys,json; print(json.load(sys.stdin)['job_id'])")
echo "Job: $JOB_ID"
```

### Check podcast job status
```bash
curl -s $ON/api/podcasts/jobs/$JOB_ID | python3 -c "
import sys, json
j = json.load(sys.stdin)
print(f'Status: {j.get(\"status\")}')
print(f'Progress: {j.get(\"progress\",\"\")}')
"
```

### Wait for podcast to complete
```bash
while true; do
  STATUS=$(curl -s $ON/api/podcasts/jobs/$JOB_ID | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))")
  echo "Podcast status: $STATUS"
  if [ "$STATUS" = "complete" ] || [ "$STATUS" = "error" ]; then break; fi
  sleep 10
done
```

### List podcast episodes
```bash
curl -s $ON/api/podcasts/episodes | python3 -c "
import sys, json
eps = json.load(sys.stdin)
for ep in eps:
    print(f'{ep[\"id\"]}: {ep.get(\"name\",\"Untitled\")} [{ep.get(\"status\",\"\")}]')
"
```

### Download podcast audio
```bash
EPISODE_ID="<episode_id>"
curl -s $ON/api/podcasts/episodes/$EPISODE_ID/audio \
  --output ~/work/research-vault/YouTube/podcast-$(date +%Y%m%d).mp3
echo "Saved to vault"
```

---

## Vault Integration

Save any result to the Obsidian research vault at `~/work/research-vault/`.

### Save research session note
```bash
VAULT=~/work/research-vault
TOPIC="my-topic"
DATE=$(date +%Y-%m-%d)
mkdir -p $VAULT/Research

cat > $VAULT/Research/$DATE-$TOPIC.md << ENDNOTE
# $TOPIC

**Date:** $DATE
**Notebook ID:** $NB_ID
**Source type:** Open Notebook

## Summary


## Key Findings
-

## Sources


## Notes

ENDNOTE
echo "Saved to $VAULT/Research/$DATE-$TOPIC.md"
```

---

## Models

### List available models
```bash
curl -s $ON/api/models | python3 -c "
import sys, json
models = json.load(sys.stdin)
for m in models:
    print(f'{m[\"id\"]}: {m.get(\"name\",\"\")} ({m.get(\"provider\",\"\")})')
" | head -20
```

### Get default models
```bash
curl -s $ON/api/models/defaults | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), indent=2))"
```

---

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused` | Containers stopped | `cd ~/work/open-notebook && docker compose up -d` |
| Source stuck in `processing` | Slow URL or rate limit | Wait 60s, then `curl $ON/api/sources/{id}/retry -X POST` |
| `422 Unprocessable Entity` | Missing required field | Check the request body matches schema |
| Empty model ID in defaults | No models configured | Go to http://localhost:8502 → Settings → Models and configure an AI provider |
| Podcast job `error` | No TTS model set | Configure text-to-speech model in UI settings |

---

## Parallel Agent Guidance

- Always use explicit `notebook_id` — there is no global "active notebook" context
- Each agent should use its own `session_id` for chat
- Source processing is async — always poll `/api/sources/{id}/status` before using for chat
- Use `async_processing: "true"` for URL sources to avoid timeouts
