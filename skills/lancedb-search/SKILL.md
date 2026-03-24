---
name: lancedb-search
description: Semantic search across the OLS research paper databases in LanceDB at ~/data/lancedb. Search sociology, psychology, neuroscience, environmentalism papers (3,565 total) or the cross-domain concept index. Use when asked to find papers, search research, look up studies, or find what's already been ingested.
---

# LanceDB Research Search

Semantic + keyword search across 3,565 ingested academic papers in 4 domain tables.

**Database:** `~/data/lancedb` (→ `/lab/data/lancedb`)

| Table | Domain | Rows |
|-------|--------|------|
| `sociology_papers` | Sociology, social theory | 873 |
| `psychology_papers` | Psychology, cognitive science | 914 |
| `neuroscience_papers` | Neuroscience, brain research | 852 |
| `environmentalism_papers` | Environmental science, ecology | 926 |
| `cross_domain_index` | Cross-domain concepts | 0 (building) |

**Paper schema:** `id, doi, title, authors, year, journal, citation_count, study_type, chunk_type, chunk_text, vector, domain, keywords, methodology_tags, open_access, source, collected_date, quality_score`

---

## When This Skill Activates

**Explicit:** `/lancedb-search`, "search my papers", "search LanceDB"

**Intent detection:**
- "Find papers about X"
- "What do I have on X in my research database?"
- "Search my ingested papers for X"
- "Are there any studies on X in my database?"
- "Find sociology/psychology/neuroscience papers about X"
- "What papers relate to X?"

---

## Quick Reference

```bash
python3 ~/work/research-vault/scripts/lancedb_search.py "<query>" [--table sociology_papers] [--limit 10]
```

Or use inline Python (no script needed):

```bash
python3 -c "
import lancedb
db = lancedb.connect('/home/joel/data/lancedb')
t = db.open_table('sociology_papers')
results = t.search('<your query>').limit(5).to_pandas()
for _, r in results.iterrows():
    print(f'{r[\"title\"]} ({r[\"year\"]}) — {r[\"journal\"]}')
"
```

---

## Semantic Search (Vector)

### Search a single domain table
```bash
python3 -c "
import lancedb
db = lancedb.connect('/home/joel/data/lancedb')
t = db.open_table('sociology_papers')

results = t.search('social capital and community resilience').limit(10).to_pandas()
print(f'Found {len(results)} results:\n')
for _, r in results.iterrows():
    print(f'  [{r[\"year\"]}] {r[\"title\"]}')
    print(f'         Authors: {r[\"authors\"][:80]}')
    print(f'         Journal: {r[\"journal\"]}')
    print(f'         DOI: {r.get(\"doi\",\"\")}')
    print()
"
```

### Search all 4 domain tables at once
```bash
python3 -c "
import lancedb, pandas as pd

db = lancedb.connect('/home/joel/data/lancedb')
tables = ['sociology_papers', 'psychology_papers', 'neuroscience_papers', 'environmentalism_papers']
query = 'collective behavior and group dynamics'
all_results = []

for tname in tables:
    t = db.open_table(tname)
    res = t.search(query).limit(3).to_pandas()
    res['_table'] = tname
    all_results.append(res)

combined = pd.concat(all_results, ignore_index=True)
for _, r in combined.iterrows():
    print(f'[{r[\"_table\"].replace(\"_papers\",\"\")}] [{r[\"year\"]}] {r[\"title\"]}')
    print(f'  {r[\"journal\"]}')
    print()
"
```

---

## Keyword / Filter Search

### Filter by year range
```bash
python3 -c "
import lancedb
db = lancedb.connect('/home/joel/data/lancedb')
t = db.open_table('psychology_papers')

results = t.search('cognitive load theory') \
    .where('year >= 2015 AND year <= 2024') \
    .limit(10).to_pandas()

for _, r in results.iterrows():
    print(f'[{r[\"year\"]}] {r[\"title\"]} — {r[\"journal\"]}')
"
```

### Filter by methodology
```bash
python3 -c "
import lancedb
db = lancedb.connect('/home/joel/data/lancedb')
t = db.open_table('sociology_papers')

# Filter to empirical studies only
results = t.search('inequality and education') \
    .where(\"study_type = 'empirical'\") \
    .limit(10).to_pandas()

for _, r in results.iterrows():
    print(f'{r[\"title\"]} [{r[\"study_type\"]}]')
"
```

### Open access papers only
```bash
python3 -c "
import lancedb
db = lancedb.connect('/home/joel/data/lancedb')
t = db.open_table('neuroscience_papers')

results = t.search('neuroplasticity') \
    .where('open_access = true') \
    .limit(10).to_pandas()

for _, r in results.iterrows():
    print(f'{r[\"title\"]} | DOI: {r.get(\"doi\",\"N/A\")}')
"
```

---

## Table Stats

```bash
python3 -c "
import lancedb
db = lancedb.connect('/home/joel/data/lancedb')
tables = ['sociology_papers','psychology_papers','neuroscience_papers','environmentalism_papers']
for tname in tables:
    t = db.open_table(tname)
    print(f'{tname:35s}: {t.count_rows():5d} rows')
"
```

---

## Pipe Results to Open Notebook

After finding relevant papers, add them to Open Notebook as sources:

```bash
python3 -c "
import lancedb, json
db = lancedb.connect('/home/joel/data/lancedb')
t = db.open_table('sociology_papers')
results = t.search('social movements').limit(5).to_pandas()

# Output DOI URLs for Open Notebook
for _, r in results.iterrows():
    if r.get('doi'):
        print(f'https://doi.org/{r[\"doi\"]}')
    elif r.get('source'):
        print(r['source'])
" | while read url; do
  echo "Adding: $url"
  curl -s -X POST http://localhost:5055/api/sources \
    -H 'Content-Type: application/json' \
    -d "{\"type\":\"url\",\"url\":\"$url\",\"notebook_id\":\"$NB_ID\",\"async_processing\":\"true\"}"
  echo ""
done
```

---

## Save Search Results to Vault

```bash
python3 -c "
import lancedb, json
from datetime import date

db = lancedb.connect('/home/joel/data/lancedb')
query = 'social capital'
tables = ['sociology_papers','psychology_papers']

lines = [f'# LanceDB Search: {query}', f'**Date:** {date.today()}', '']
for tname in tables:
    t = db.open_table(tname)
    results = t.search(query).limit(5).to_pandas()
    lines.append(f'## {tname.replace(\"_papers\",\"\").title()}')
    for _, r in results.iterrows():
        doi_url = f'https://doi.org/{r[\"doi\"]}' if r.get('doi') else ''
        lines.append(f'- [{r[\"title\"]}]({doi_url}) ({r[\"year\"]}) — {r[\"journal\"]}')
    lines.append('')

print('\n'.join(lines))
" > ~/work/research-vault/Research/$(date +%Y-%m-%d)-lancedb-search.md
echo "Saved to vault"
```

---

## Notes

- The `vector` column stores embeddings — searching uses cosine similarity by default
- `cross_domain_index` is currently empty (0 rows) — it will populate as the Kestra ingestion pipeline runs
- For best results, use natural language queries rather than single keywords
- High `quality_score` papers are peer-reviewed with citations
- Use `methodology_tags` to filter by research method (qualitative, quantitative, meta-analysis, etc.)
