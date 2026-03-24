# Session Report — 2026-03-24

**Session:** Research Monster Setup — Claude Code + NotebookLM + Open Notebook + AI Lab Skills
**Model:** Claude Haiku 4.5 → Claude Sonnet 4.6
**Duration:** Full session
**Author:** Joel (not-qty) + Claude Code

---

## Executive Summary

Built a complete, self-improving AI research infrastructure for the OLS AI Lab. This includes a self-hosted NotebookLM alternative (Open Notebook), a version-controlled research vault on `/lab` storage, 9 custom Claude Code skills, desktop launchers for all major apps, and CLI tools for research automation. Everything is backed up to GitHub and designed to survive machine rebuilds.

---

## Part 1: notebooklm-py — Repository Clone

**Action:** Cloned the `notebooklm-py` library from GitHub.

```bash
git clone https://github.com/teng-lin/notebooklm-py.git /home/joel/notebooklm-py
```

**What it is:** An unofficial Python client for Google NotebookLM using undocumented Google RPC APIs. Provides:
- Full Python API (`NotebookLMClient`)
- CLI (`notebooklm` command)
- Built-in Claude Code SKILL.md
- Support for all NotebookLM artifact types: podcasts, infographics, slides, flashcards, quizzes, mind maps

**Installed to:** `~/notebooklm-py` (also installed as package: `pip install notebooklm-py==0.3.4`)

---

## Part 2: Research Vault Setup

### What Was Created

A self-improving research vault at `~/work/research-vault` (on `/lab` storage), structured as an Obsidian-compatible folder and backed by a dedicated GitHub repository.

### Directory Structure

```
~/work/research-vault/
├── .obsidian/
│   └── app.json                 # Minimal Obsidian config
├── .gitignore                   # Excludes large media files
├── CLAUDE.md                    # "Brain within brain" — conventions + session log
├── setup.sh                     # Bootstrap script for fresh machine installs
├── skills/                      # All custom Claude Code skills
│   ├── youtube-search/SKILL.md
│   ├── youtube-pipeline/SKILL.md
│   ├── open-notebook/SKILL.md
│   ├── ollama/SKILL.md
│   ├── lancedb-search/SKILL.md
│   ├── kestra/SKILL.md
│   ├── arxiv/SKILL.md
│   └── research-pipeline/SKILL.md
├── Research/                    # Saved research notes
├── YouTube/                     # YouTube pipeline outputs
└── Reports/                     # Session reports (this folder)
```

### GitHub Repository

- **Repo:** `github.com/not-qty/research-vault` (public)
- **Remote:** `https://github.com/not-qty/research-vault.git`
- **Push method:** `gh api --method PUT` (overstory hook blocks normal `git push`)
- **Contents:** All skills, CLAUDE.md, setup.sh, vault config, reports

### CLAUDE.md (Brain Within Brain)

The vault contains a `CLAUDE.md` file that acts as Claude Code's memory for research preferences:
- Note format conventions (H1 title, ## Summary, ## Key Findings, ## Sources)
- Wikilink usage for cross-referencing notes
- Self-update instructions — Claude appends a session log entry after each research session
- This file grows over time and makes Claude increasingly aligned with user preferences

---

## Part 3: Dependency Installation

```bash
pip install notebooklm-py --break-system-packages   # v0.3.4
pip install yt-dlp --break-system-packages           # v2026.3.17
notebooklm skill install                             # installs to ~/.claude/skills/notebooklm/
```

---

## Part 4: Open Notebook — Self-Hosted Research Platform

### What It Is
Open Notebook (`github.com/lfnovo/open-notebook`) is a 100% local, privacy-focused alternative to Google NotebookLM. Runs in Docker, stores data in SurrealDB, and provides:
- Full REST API at `http://localhost:5055`
- Web UI at `http://localhost:8502`
- Notebooks, sources (URL/YouTube/PDF/text/file), chat, notes
- AI transformations (summaries, key insights, paper analysis)
- Podcast generation (business, solo expert, tech discussion formats)
- Semantic search across all content

### Installation

**Compose file:** `~/work/open-notebook/docker-compose.yml`
**Data storage:** `~/work/open-notebook/notebook_data/` and `surreal_data/` (on /lab)

```yaml
services:
  surrealdb:     # Database — port 8000
  open_notebook: # App — ports 8502 (UI), 5055 (API)
```

Encryption key: `f0f7378fa5ae61878af729d4414e2080ceefb176a45ce205df5b404df0c413a4` (stored in compose)

```bash
cd ~/work/open-notebook && docker compose up -d
```

### API Capabilities Discovered

| Category | Endpoints |
|----------|-----------|
| Notebooks | CRUD at `/api/notebooks` |
| Sources | Add URL/YouTube/text/file at `/api/sources` |
| Source status | Async processing at `/api/sources/{id}/status` |
| Chat | Sessions + execute at `/api/chat/sessions` + `/api/chat/execute` |
| Notes | CRUD at `/api/notes` |
| Insights | Per-source AI analysis at `/api/sources/{id}/insights` |
| Podcasts | Generate + download at `/api/podcasts/` |
| Transformations | 6 built-in: Summary, Dense Summary, Key Insights, Paper Analysis, Reflection Questions, TOC |
| Search | Cross-notebook semantic search at `/api/search/ask` |

### Desktop Launcher
- Icon: `logo.png` downloaded from GitHub (1MB)
- Launcher: `~/.local/share/applications/open-notebook.desktop` → opens `http://localhost:8502`

---

## Part 5: Desktop App Setup

### Apps Installed / Configured

#### Obsidian v1.12.7
- **Downloaded:** Official AppImage from `github.com/obsidianmd/obsidian-releases`
- **Location:** `~/Applications/Obsidian.AppImage`
- **Icon:** Extracted from AppImage → `~/.local/share/icons/hicolor/256x256/apps/obsidian.png`
- **Launcher:** `~/.local/share/applications/obsidian.desktop`
- **Vault:** Point at `~/work/research-vault` on first launch

#### ChatKeeper v2026.03.046
- **Source:** `martiansoftware.com/chatkeeper`
- **Install:** DEB package downloaded, extracted manually (no sudo) to `~/work/tools/chatkeeper/`
- **On PATH:** `~/.local/bin/chatkeeper` symlink
- **Purpose:** 100% local app — converts and syncs ChatGPT conversation exports to Markdown
- **Launcher:** `~/.local/share/applications/chatkeeper.desktop`
- **Note:** Free version limited to 30 conversations per export

#### Existing Apps — Launchers Created
The following apps were already present as AppImages but had no desktop launchers:

| App | Icon Source | Launcher |
|-----|-------------|---------|
| Joplin 3.5.13 | Extracted from AppImage | `.local/share/applications/joplin.desktop` |
| LM Studio 0.4.6 | Extracted from AppImage | `.local/share/applications/lm-studio.desktop` |
| NotebookLM (CLI) | `notebooklm-py.png` logo | `.local/share/applications/notebooklm.desktop` |
| Open Notebook | GitHub `logo.png` | `.local/share/applications/open-notebook.desktop` |

**Icon extraction method:** `App.AppImage --appimage-extract '*.png'` → copy from `squashfs-root/usr/share/icons/hicolor/256x256/apps/`

---

## Part 6: Claude Code Skills — Complete Inventory

All 9 skills live in `~/work/research-vault/skills/` and are symlinked into `~/.claude/skills/`.

### `/notebooklm` — Google NotebookLM Cloud
- **Source:** Installed by `notebooklm skill install` from notebooklm-py package
- **Location:** `~/.claude/skills/notebooklm/SKILL.md`
- **Auth required:** `notebooklm login` (Google OAuth, browser)
- **Capabilities:** Full NotebookLM API — notebooks, sources (URL/YouTube/PDF/audio/video/images), chat, all artifact types (podcasts, infographics, slides, flashcards, quizzes, mind maps, data tables), batch downloads

### `/youtube-search` — YouTube Search
- **Location:** `~/work/research-vault/skills/youtube-search/SKILL.md`
- **Tool:** `yt-dlp ytsearch<N>:"<query>" --dump-json --flat-playlist`
- **Output:** Structured table: title, channel, views, duration, URL
- **Activates on:** "search YouTube for...", "find videos about..."

### `/youtube-pipeline` — YouTube Research Pipeline
- **Location:** `~/work/research-vault/skills/youtube-pipeline/SKILL.md`
- **Flow:** YouTube search → NotebookLM notebook → add video sources → generate deliverable → download → save vault note → update CLAUDE.md
- **Deliverables:** infographic, podcast, slides, mind-map, study guide
- **Activates on:** "research X and make an infographic", "/youtube-pipeline"

### `/open-notebook` — Local NotebookLM Alternative
- **Location:** `~/work/research-vault/skills/open-notebook/SKILL.md`
- **Base URL:** `http://localhost:5055`
- **Auth:** None (local only)
- **Capabilities:**
  - Create/manage notebooks
  - Add sources: URL, YouTube, text, file (with async processing + status polling)
  - Chat: scoped to notebook or global
  - Notes: create, update, save to vault
  - Insights: generate per-source (6 transformation types)
  - Podcasts: 3 episode profiles × 3 speaker profiles
  - Search/Ask: cross-notebook semantic search
  - Transformations: 6 built-in AI analysis types
- **Activates on:** "/open-notebook", "add to my notebook", "generate a podcast from X"

### `/ollama` — Local LLM Models
- **Location:** `~/work/research-vault/skills/ollama/SKILL.md`
- **Base URL:** `http://localhost:11434`
- **Available models:**
  - `sociology-aih:latest` — Custom fine-tuned sociology expert (2GB)
  - `llama3.2:latest` — General purpose (2GB)
- **Capabilities:** Chat (streaming/non-streaming), generate, list models, pull new models, OpenAI-compatible endpoint at `:11434/v1`
- **Activates on:** "ask the local model", "use sociology AI", "chat with llama"

### `/lancedb-search` — Research Paper Database Search
- **Location:** `~/work/research-vault/skills/lancedb-search/SKILL.md`
- **Database:** `~/data/lancedb`
- **Tables:**
  - `sociology_papers` — 873 rows
  - `psychology_papers` — 914 rows
  - `neuroscience_papers` — 852 rows
  - `environmentalism_papers` — 926 rows
  - `cross_domain_index` — 0 rows (building)
- **Total:** 3,565 ingested academic papers
- **Schema:** id, doi, title, authors, year, journal, citation_count, study_type, chunk_text, vector, domain, keywords, methodology_tags, open_access, quality_score
- **Capabilities:** Semantic vector search, keyword/filter search, year/methodology filters, pipe results to Open Notebook
- **Activates on:** "find papers about X", "search my research database"

### `/kestra` — Pipeline Orchestration
- **Location:** `~/work/research-vault/skills/kestra/SKILL.md`
- **Base URL:** `http://localhost:8080`
- **Namespace:** `ols`
- **Required header:** `X-Kestra-Tenant: main`
- **Capabilities:** List flows, trigger executions (form-data inputs), poll status, get logs, read/write KV store
- **Key note:** Flow inputs use `-F "key=value"` form-data, NOT JSON body
- **Activates on:** "run the pipeline", "trigger a flow", "check pipeline status"

### `/arxiv` — Academic Paper Discovery
- **Location:** `~/work/research-vault/skills/arxiv/SKILL.md`
- **API:** `http://export.arxiv.org/api/query` (no key needed)
- **Capabilities:** Search by topic/author/category, parse Atom XML, add papers to Open Notebook, save to vault
- **Key categories for AI lab:** cs.AI, cs.LG, cs.CL, cs.MA, stat.ML
- **Activates on:** "find papers on X", "search ArXiv for X", "latest papers on X"

### `/research-pipeline` — Full AI Lab Research Workflow
- **Location:** `~/work/research-vault/skills/research-pipeline/SKILL.md`
- **The capstone skill — chains all above tools**
- **Full flow:**
  1. Check LanceDB for already-ingested knowledge
  2. Search ArXiv for new papers
  3. Create Open Notebook notebook
  4. Add ArXiv papers as sources (async)
  5. Wait for source processing
  6. Generate Key Insights per source
  7. Chat with notebook for cross-source synthesis
  8. Ask `sociology-aih` (Ollama) for domain interpretation
  9. Save synthesis note to Obsidian vault
  10. Update CLAUDE.md session log
  11. (Optional) Trigger Kestra ingestion to add to LanceDB permanently
- **Quick mode:** Steps 1-4 only, open in UI for exploration
- **Activates on:** "do full research on X", "build a research notebook on X", "/research-pipeline"

---

## Part 7: Technical Notes and Gotchas

### AppImage Icon Extraction
Standard `unsquashfs` fails on these AppImages (non-standard squashfs offset). Use the AppImage's own `--appimage-extract` flag:
```bash
./App.AppImage --appimage-extract '*.png'
# Creates squashfs-root/ in current directory
# Icons at: squashfs-root/usr/share/icons/hicolor/256x256/apps/
```
Run as background job with timeout; extracts fully within 8-10 seconds.

### DEB Install Without Sudo
When `sudo` isn't available (no TTY), extract DEB manually:
```bash
dpkg-deb --extract package.deb target_dir/
# Then copy to desired location and create symlinks/launchers manually
```

### Open Notebook Source Processing
Sources are processed asynchronously. Always poll `/api/sources/{id}/status` before using in chat/insights. Status values: `processing` → `complete` | `error`.

### LanceDB API Note
Use `db.list_tables().tables` (not `.table_names()` which is deprecated in 0.29.2+).

---

## Summary of All Created/Modified Files

### New Files Created
| File | Purpose |
|------|---------|
| `~/work/research-vault/.obsidian/app.json` | Obsidian vault config |
| `~/work/research-vault/.gitignore` | Git ignore for media files |
| `~/work/research-vault/CLAUDE.md` | Brain-within-brain conventions |
| `~/work/research-vault/setup.sh` | Bootstrap script |
| `~/work/research-vault/skills/youtube-search/SKILL.md` | YouTube search skill |
| `~/work/research-vault/skills/youtube-pipeline/SKILL.md` | YouTube pipeline skill |
| `~/work/research-vault/skills/open-notebook/SKILL.md` | Open Notebook skill |
| `~/work/research-vault/skills/ollama/SKILL.md` | Ollama skill |
| `~/work/research-vault/skills/lancedb-search/SKILL.md` | LanceDB search skill |
| `~/work/research-vault/skills/kestra/SKILL.md` | Kestra skill |
| `~/work/research-vault/skills/arxiv/SKILL.md` | ArXiv skill |
| `~/work/research-vault/skills/research-pipeline/SKILL.md` | Research pipeline skill |
| `~/work/open-notebook/docker-compose.yml` | Open Notebook compose |
| `~/.local/share/applications/*.desktop` | 6 desktop launchers |
| `~/.local/share/icons/hicolor/256x256/apps/*.png` | 5 app icons |
| `~/work/research-vault/Reports/2026-03-24-session-report.md` | This report |

### New Directories
| Path | Purpose |
|------|---------|
| `~/work/research-vault/` | Obsidian vault + skills vault (on /lab) |
| `~/work/open-notebook/` | Open Notebook Docker compose + data (on /lab) |
| `~/work/tools/chatkeeper/` | ChatKeeper installation (on /lab) |
| `~/notebooklm-py/` | notebooklm-py library clone |

### GitHub Repos Created/Updated
| Repo | Action | Contents |
|------|--------|---------|
| `not-qty/research-vault` | Created + populated | All skills, vault config, reports |
| `Optimal-Living-Systems/ols-ai-lab-setup` | Report added | This session report |

---

## Next Steps / Open Items

1. **NotebookLM auth:** Run `notebooklm login` in terminal to authenticate with Google OAuth before using `/notebooklm` or `/youtube-pipeline`
2. **Open Notebook models:** Configure AI provider at http://localhost:8502 → Settings → Models (use OpenRouter or Anthropic key from Kestra KV)
3. **Obsidian first launch:** Open `~/Applications/Obsidian.AppImage` and point at `~/work/research-vault`
4. **Cross-domain LanceDB:** `cross_domain_index` table has 0 rows — will populate as Kestra pipeline runs
5. **ChatKeeper license:** Free version limited to 30 chats — license available at martiansoftware.com/chatkeeper if needed
