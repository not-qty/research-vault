---
name: arxiv
description: Search ArXiv for academic papers and route them into the research pipeline. Find papers by topic, author, or category, then add to Open Notebook, save to vault, or queue for LanceDB ingestion. No install required — uses curl + python3. Use when asked to find papers, search academic literature, or discover research on a topic.
---

# ArXiv Research Search

Search 2M+ academic papers across AI, CS, physics, math, biology, economics, and more. No API key needed.

**API:** `http://export.arxiv.org/api/query`
**Docs:** https://arxiv.org/help/api

---

## When This Skill Activates

**Explicit:** `/arxiv`, "search arxiv", "find papers on"

**Intent detection:**
- "Find recent papers on X"
- "Search ArXiv for X"
- "What are the latest papers on X?"
- "Find papers by [author]"
- "Get AI papers on X"
- "Find cs.AI papers about X"

---

## Key ArXiv Categories for AI Lab Work

| Category | Description |
|----------|-------------|
| `cs.AI` | Artificial Intelligence |
| `cs.LG` | Machine Learning |
| `cs.CL` | Computation and Language (NLP) |
| `cs.CV` | Computer Vision |
| `cs.MA` | Multi-Agent Systems |
| `stat.ML` | Statistics — Machine Learning |
| `q-bio.NC` | Neurons and Cognition |
| `econ.GN` | General Economics |

For sociology/social science: use keyword search (no dedicated category).

---

## Search Papers

### Basic search by topic
```bash
QUERY="AI agents tool use"
RESULTS=$(curl -s "http://export.arxiv.org/api/query?search_query=all:${QUERY// /+}&start=0&max_results=10&sortBy=relevance")

echo "$RESULTS" | python3 -c "
import sys
import xml.etree.ElementTree as ET

ns = {'atom': 'http://www.w3.org/2005/Atom', 'arxiv': 'http://arxiv.org/schemas/atom'}
root = ET.fromstring(sys.stdin.read())

entries = root.findall('atom:entry', ns)
print(f'Found {len(entries)} papers:\n')
for e in entries:
    title = e.find('atom:title', ns).text.strip().replace('\n',' ')
    authors = [a.find('atom:name', ns).text for a in e.findall('atom:author', ns)][:3]
    published = e.find('atom:published', ns).text[:10]
    pdf_url = next((l.get('href') for l in e.findall('atom:link', ns) if l.get('title')=='pdf'), '')
    arxiv_id = e.find('atom:id', ns).text.split('/')[-1]
    print(f'[{published}] {title}')
    print(f'  Authors: {\", \".join(authors)}')
    print(f'  ArXiv: https://arxiv.org/abs/{arxiv_id}')
    print(f'  PDF: {pdf_url}')
    print()
"
```

### Search by category (most precise for AI)
```bash
CATEGORY="cs.AI"
KEYWORDS="multi+agent+systems"
curl -s "http://export.arxiv.org/api/query?search_query=cat:${CATEGORY}+AND+all:${KEYWORDS}&start=0&max_results=10&sortBy=submittedDate&sortOrder=descending" | python3 -c "
import sys
import xml.etree.ElementTree as ET

ns = {'atom': 'http://www.w3.org/2005/Atom'}
root = ET.fromstring(sys.stdin.read())
for e in root.findall('atom:entry', ns):
    title = e.find('atom:title', ns).text.strip()
    date = e.find('atom:published', ns).text[:10]
    arxiv_id = e.find('atom:id', ns).text.split('/')[-1]
    print(f'[{date}] {title}')
    print(f'  https://arxiv.org/abs/{arxiv_id}')
    print()
"
```

### Search by author
```bash
AUTHOR="Geoffrey+Hinton"
curl -s "http://export.arxiv.org/api/query?search_query=au:${AUTHOR}&start=0&max_results=10&sortBy=submittedDate&sortOrder=descending" | python3 -c "
import sys
import xml.etree.ElementTree as ET

ns = {'atom': 'http://www.w3.org/2005/Atom'}
root = ET.fromstring(sys.stdin.read())
for e in root.findall('atom:entry', ns):
    title = e.find('atom:title', ns).text.strip()
    date = e.find('atom:published', ns).text[:10]
    arxiv_id = e.find('atom:id', ns).text.split('/')[-1]
    print(f'[{date}] {title} — https://arxiv.org/abs/{arxiv_id}')
"
```

### Get most recent papers in a category
```bash
curl -s "http://export.arxiv.org/api/query?search_query=cat:cs.LG&start=0&max_results=15&sortBy=submittedDate&sortOrder=descending" | python3 -c "
import sys
import xml.etree.ElementTree as ET

ns = {'atom': 'http://www.w3.org/2005/Atom'}
root = ET.fromstring(sys.stdin.read())
for e in root.findall('atom:entry', ns):
    title = e.find('atom:title', ns).text.strip().replace('\n',' ')
    date = e.find('atom:published', ns).text[:10]
    arxiv_id = e.find('atom:id', ns).text.split('/')[-1]
    print(f'[{date}] {title}')
    print(f'  https://arxiv.org/abs/{arxiv_id}')
"
```

---

## Add Papers to Open Notebook

```bash
# Search and pipe abstract URLs directly into Open Notebook
QUERY="large+language+model+agents"
NB_ID="<your-notebook-id>"

curl -s "http://export.arxiv.org/api/query?search_query=all:${QUERY}&max_results=5" | python3 -c "
import sys
import xml.etree.ElementTree as ET

ns = {'atom': 'http://www.w3.org/2005/Atom'}
root = ET.fromstring(sys.stdin.read())
for e in root.findall('atom:entry', ns):
    arxiv_id = e.find('atom:id', ns).text.split('/')[-1]
    print(f'https://arxiv.org/abs/{arxiv_id}')
" | while read url; do
  echo "Adding: $url"
  curl -s -X POST http://localhost:5055/api/sources \
    -H 'Content-Type: application/json' \
    -d "{\"type\":\"url\",\"url\":\"$url\",\"notebook_id\":\"$NB_ID\",\"async_processing\":\"true\"}" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'  Source ID: {r[\"id\"]}')"
done
```

---

## Save Papers to Vault

```bash
QUERY="sociology digital inequality"
DATE=$(date +%Y-%m-%d)
OUTFILE=~/work/research-vault/Research/$DATE-arxiv-$(echo $QUERY | tr ' ' '-').md

curl -s "http://export.arxiv.org/api/query?search_query=all:${QUERY// /+}&max_results=10&sortBy=relevance" | python3 -c "
import sys
import xml.etree.ElementTree as ET
from datetime import date

ns = {'atom': 'http://www.w3.org/2005/Atom'}
root = ET.fromstring(sys.stdin.read())

query = sys.argv[1] if len(sys.argv) > 1 else 'search'
lines = [
    f'# ArXiv Search: $QUERY',
    f'**Date:** {date.today()}',
    f'**Query:** $QUERY',
    '',
    '## Papers Found',
    ''
]
for e in root.findall('atom:entry', ns):
    title = e.find('atom:title', ns).text.strip().replace('\n',' ')
    authors = [a.find('atom:name', ns).text for a in e.findall('atom:author', ns)][:3]
    published = e.find('atom:published', ns).text[:10]
    summary = e.find('atom:summary', ns).text.strip()[:300]
    arxiv_id = e.find('atom:id', ns).text.split('/')[-1]
    lines.append(f'### [{title}](https://arxiv.org/abs/{arxiv_id})')
    lines.append(f'**Authors:** {\", \".join(authors)}  **Published:** {published}')
    lines.append(f'> {summary}...')
    lines.append('')

print('\n'.join(lines))
" > $OUTFILE
echo "Saved to $OUTFILE"
```

---

## Search Operators

| Operator | Example | Meaning |
|----------|---------|---------|
| `all:` | `all:transformer` | Search all fields |
| `ti:` | `ti:attention+mechanism` | Title only |
| `abs:` | `abs:reinforcement+learning` | Abstract only |
| `au:` | `au:LeCun` | Author name |
| `cat:` | `cat:cs.AI` | Category |
| `AND` | `cat:cs.LG+AND+all:agents` | Both conditions |
| `OR` | `all:BERT+OR+all:GPT` | Either condition |

---

## Notes

- URL-encode spaces as `+` in query strings
- `sortBy=submittedDate&sortOrder=descending` for newest first
- `sortBy=relevance` for best match
- Max 10 requests/second, 30,000 results max per query
- Use `max_results=10` for quick discovery, `max_results=50` for thorough searches
- ArXiv abstract pages (arxiv.org/abs/) work better as Open Notebook sources than PDF URLs
