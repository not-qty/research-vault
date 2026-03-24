---
name: research-pipeline
description: Full AI lab research pipeline — searches ArXiv + LanceDB, builds an Open Notebook, generates insights, saves to Obsidian vault, optionally triggers Kestra ingestion. The capstone skill that chains all other skills. Use when asked to do deep research on a topic, build a research notebook, or run the full pipeline on a subject.
---

# Research Pipeline — Full AI Lab Workflow

End-to-end research orchestration. Chains: ArXiv search → LanceDB check → Open Notebook → Insights → Vault note → Optional Kestra ingestion.

---

## When This Skill Activates

**Explicit:** `/research-pipeline`

**Intent detection:**
- "Do full research on X"
- "Build a research notebook on X"
- "Research X and save everything"
- "Run the full pipeline on X"
- "Find papers on X, analyze them, and save notes"
- "Deep research on X for my lab"

---

## Full Pipeline Steps

### Step 1: Check LanceDB for existing knowledge
```bash
python3 -c "
import lancedb
db = lancedb.connect('/home/joel/data/lancedb')
tables = ['sociology_papers','psychology_papers','neuroscience_papers','environmentalism_papers']
query = '<TOPIC>'
print('=== Already ingested ===')
for tname in tables:
    t = db.open_table(tname)
    results = t.search(query).limit(3).to_pandas()
    if len(results):
        print(f'\n{tname.replace(\"_papers\",\"\").upper()}:')
        for _, r in results.iterrows():
            print(f'  [{r[\"year\"]}] {r[\"title\"]}')
"
```

### Step 2: Search ArXiv for new papers
```bash
TOPIC="<your topic>"
curl -s "http://export.arxiv.org/api/query?search_query=all:${TOPIC// /+}&max_results=10&sortBy=relevance" | python3 -c "
import sys
import xml.etree.ElementTree as ET

ns = {'atom': 'http://www.w3.org/2005/Atom'}
root = ET.fromstring(sys.stdin.read())
papers = []
for e in root.findall('atom:entry', ns):
    arxiv_id = e.find('atom:id', ns).text.split('/')[-1]
    title = e.find('atom:title', ns).text.strip().replace('\n',' ')
    date = e.find('atom:published', ns).text[:10]
    papers.append({'id': arxiv_id, 'title': title, 'date': date, 'url': f'https://arxiv.org/abs/{arxiv_id}'})
    print(f'[{date}] {title}')
    print(f'  {papers[-1][\"url\"]}')
"
```

Select the most relevant papers (5–8) for the notebook.

### Step 3: Create Open Notebook
```bash
ON="http://localhost:5055"
TOPIC_SLUG=$(echo "<topic>" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

NB=$(curl -s -X POST $ON/api/notebooks \
  -H 'Content-Type: application/json' \
  -d "{\"name\": \"<Topic> Research\", \"description\": \"ArXiv + LanceDB research on <topic>\"}")
NB_ID=$(echo $NB | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Notebook: $NB_ID"
```

### Step 4: Add ArXiv papers as sources
```bash
for URL in \
  "https://arxiv.org/abs/PAPER_ID_1" \
  "https://arxiv.org/abs/PAPER_ID_2" \
  "https://arxiv.org/abs/PAPER_ID_3"; do
  echo "Adding: $URL"
  SOURCE=$(curl -s -X POST $ON/api/sources \
    -H 'Content-Type: application/json' \
    -d "{\"type\":\"url\",\"url\":\"$URL\",\"notebook_id\":\"$NB_ID\",\"async_processing\":\"true\"}")
  echo $SOURCE | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'  ID: {r[\"id\"]}')"
done
```

### Step 5: Wait for sources to process
```bash
# List sources and check all are complete
curl -s "$ON/api/notebooks/$NB_ID" | python3 -c "
import sys,json
nb = json.load(sys.stdin)
sources = nb.get('sources',[])
print(f'Sources: {len(sources)}')
for s in sources:
    print(f'  {s.get(\"id\",\"\")}: {s.get(\"title\",\"\")} [{s.get(\"status\",\"pending\")}]')
"
# Poll until all show 'complete'
sleep 30  # initial wait
```

### Step 6: Generate Key Insights per source
```bash
# Get all source IDs first
SOURCE_IDS=$(curl -s "$ON/api/notebooks/$NB_ID" | python3 -c "
import sys,json
nb = json.load(sys.stdin)
for s in nb.get('sources',[]): print(s['id'])
")

for SRC_ID in $SOURCE_IDS; do
  echo "Generating insights for $SRC_ID..."
  curl -s -X POST "$ON/api/sources/$SRC_ID/insights" \
    -H 'Content-Type: application/json' \
    -d '{"transformation_id": "transformation:91k9npful3eaen8tjq5o"}' > /dev/null
done
```

### Step 7: Chat with notebook for synthesis
```bash
SESSION=$(curl -s -X POST "$ON/api/chat/sessions" \
  -H 'Content-Type: application/json' \
  -d "{\"title\": \"<Topic> Synthesis\"}")
SESSION_ID=$(echo $SESSION | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

# Ask for synthesis
SYNTHESIS=$(curl -s -X POST "$ON/api/chat/execute" \
  -H 'Content-Type: application/json' \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"message\": \"Synthesize the key findings across all sources. What are the main themes, areas of consensus, open questions, and research gaps?\",
    \"context\": {\"notebook_id\": \"$NB_ID\"}
  }")

echo $SYNTHESIS | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))"
```

### Step 8: Ask sociology-aih for domain interpretation (optional)
```bash
# Use local Ollama model for sociology-specific framing
curl -s -X POST http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d "{
    \"model\": \"sociology-aih:latest\",
    \"messages\": [{
      \"role\": \"user\",
      \"content\": \"Given research on <topic>, what are the key sociological implications and how does this connect to existing social theory?\"
    }],
    \"stream\": false
  }" | python3 -c "import sys,json; print(json.load(sys.stdin)['message']['content'])"
```

### Step 9: Save synthesis note to vault
```bash
VAULT=~/work/research-vault
TOPIC="<topic>"
TOPIC_SLUG=$(echo "$TOPIC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
DATE=$(date +%Y-%m-%d)
mkdir -p $VAULT/Research

cat > $VAULT/Research/$DATE-$TOPIC_SLUG.md << ENDNOTE
# $TOPIC Research

**Date:** $DATE
**Open Notebook ID:** $NB_ID
**Sources:** ArXiv papers (see below)

## Summary
<paste synthesis from Step 7>

## Key Findings
-
-
-

## Research Gaps
-

## Sources

| Title | ArXiv | Year |
|-------|-------|------|

## Sociology Interpretation
<paste Ollama response from Step 8>

## Next Steps
- [ ] Ingest new papers to LanceDB
- [ ] Add to sociology-aih training dataset
ENDNOTE

echo "Saved: $VAULT/Research/$DATE-$TOPIC_SLUG.md"
```

### Step 10: Update vault CLAUDE.md
```bash
cat >> ~/work/research-vault/CLAUDE.md << ENDLOG

### $DATE — $TOPIC
- Notebook ID: $NB_ID
- ArXiv papers added: <count>
- Key finding: <one sentence>
ENDLOG
```

### Step 11 (Optional): Trigger Kestra ingestion
```bash
# Trigger LanceDB ingestion flow to add new papers permanently
EXEC=$(curl -s -X POST "http://localhost:8080/api/v1/executions/ols/<ingestion-flow-id>" \
  -H "X-Kestra-Tenant: main" \
  -F "source=arxiv" \
  -F "topic=$TOPIC_SLUG")
EXEC_ID=$(echo $EXEC | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Kestra ingestion started: $EXEC_ID"
```

---

## Quick Mode (Fast Research)

For quick topic exploration without full pipeline:

```bash
TOPIC="<topic>"
ON="http://localhost:5055"

# 1. Create notebook
NB_ID=$(curl -s -X POST $ON/api/notebooks -H 'Content-Type: application/json' \
  -d "{\"name\":\"Quick: $TOPIC\"}" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

# 2. Add top 3 ArXiv papers
curl -s "http://export.arxiv.org/api/query?search_query=all:${TOPIC// /+}&max_results=3&sortBy=relevance" | \
python3 -c "
import sys, xml.etree.ElementTree as ET
ns={'atom':'http://www.w3.org/2005/Atom'}
root=ET.fromstring(sys.stdin.read())
for e in root.findall('atom:entry',ns):
    print('https://arxiv.org/abs/'+e.find('atom:id',ns).text.split('/')[-1])
" | while read url; do
  curl -s -X POST $ON/api/sources -H 'Content-Type: application/json' \
    -d "{\"type\":\"url\",\"url\":\"$url\",\"notebook_id\":\"$NB_ID\",\"async_processing\":\"true\"}" > /dev/null
  echo "Added: $url"
done

echo "Notebook $NB_ID ready — open http://localhost:8502 to explore"
```

---

## Pipeline Summary Card

```
ArXiv search (10 papers)
    ↓
LanceDB check (existing knowledge)
    ↓
Open Notebook (create + add sources)
    ↓
Key Insights transformation (per source)
    ↓
Synthesis chat (cross-source themes)
    ↓
sociology-aih interpretation (Ollama)
    ↓
Vault note (~/work/research-vault/Research/)
    ↓
Kestra ingestion (optional → LanceDB)
```
