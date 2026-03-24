# Claude Code Research Vault

<p align="left">
  <img src="https://raw.githubusercontent.com/lfnovo/open-notebook/main/logo.png" alt="research vault" width="96">
</p>

**A self-improving AI research system for Claude Code.**

Nine custom skills that turn Claude Code into a full research orchestrator — finding papers, driving a local NotebookLM alternative, querying vector databases, running local LLMs, managing data pipelines, and saving everything to a version-controlled Obsidian vault that grows smarter over time.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skills-blueviolet)](https://claude.ai/code)
[![Open Notebook](https://img.shields.io/badge/Open%20Notebook-1.8.1-blue)](https://github.com/lfnovo/open-notebook)
[![notebooklm-py](https://img.shields.io/badge/notebooklm--py-0.3.4-green)](https://github.com/teng-lin/notebooklm-py)

---

## What You Can Build

- **Academic research pipelines** — search ArXiv, load papers into a local notebook, generate insights, and save structured notes to your vault in one command
- **YouTube research workflows** — find videos on any topic, send them to NotebookLM (local or cloud), generate podcasts or infographics, archive everything
- **Private AI notebooks** — add any URL, PDF, or text to a fully local research platform with no data leaving your machine
- **Cross-database knowledge queries** — semantic search across thousands of ingested papers using natural language
- **Automated pipeline control** — trigger and monitor data workflows directly from Claude Code
- **Self-improving research memory** — every session updates a `CLAUDE.md` file that teaches Claude your preferences, making each session smarter than the last

---

## Why This Exists

Most AI research workflows share the same problem: great answers that disappear when you close the tab. Notes scattered across tools. No continuity between sessions. No way for the AI to learn your preferences over time.

This vault solves that by treating Claude Code as a **research orchestrator** — not just a chat window. Claude drives real tools (local databases, REST APIs, local LLMs, workflow engines) via skills, and saves everything to a structured vault it can read back next session.

The second problem this solves: **privacy**. Google's NotebookLM is powerful, but your research goes to Google's servers. This system is built around [Open Notebook](https://github.com/lfnovo/open-notebook) — a self-hosted, 100% local alternative that gives you the same capabilities with your data staying on your own hardware.

---

## The Nine Skills

### Research Discovery

| Skill | Purpose | Key Tool |
|-------|---------|---------|
| [`/arxiv`](skills/arxiv/SKILL.md) | Search 2M+ academic papers by topic, author, or category | ArXiv public API (no key needed) |
| [`/lancedb-search`](skills/lancedb-search/SKILL.md) | Semantic search across locally-ingested paper databases | LanceDB vector search |
| [`/youtube-search`](skills/youtube-search/SKILL.md) | Search YouTube and return structured metadata | yt-dlp |

### Research Analysis

| Skill | Purpose | Key Tool |
|-------|---------|---------|
| [`/open-notebook`](skills/open-notebook/SKILL.md) | Full local research platform — notebooks, sources, chat, podcasts | Open Notebook REST API |
| [`/notebooklm`](https://github.com/teng-lin/notebooklm-py) | Google NotebookLM cloud — all artifact types | notebooklm-py |
| [`/ollama`](skills/ollama/SKILL.md) | Chat with locally-running LLMs without leaving the terminal | Ollama API |

### Pipeline & Automation

| Skill | Purpose | Key Tool |
|-------|---------|---------|
| [`/kestra`](skills/kestra/SKILL.md) | Trigger and monitor data workflow executions | Kestra REST API |
| [`/youtube-pipeline`](skills/youtube-pipeline/SKILL.md) | YouTube → NotebookLM → deliverable → vault (end-to-end) | yt-dlp + NotebookLM |
| [`/research-pipeline`](skills/research-pipeline/SKILL.md) | **Full research pipeline** — chains all other skills | Everything |

---

## Open Notebook — The Local Research Brain

[Open Notebook](https://github.com/lfnovo/open-notebook) is the foundation of the local research stack. It's a self-hosted, privacy-first alternative to Google NotebookLM that runs entirely in Docker on your own machine.

### Why We Built a Skill For It

Open Notebook has a full REST API at `localhost:5055` — but without a skill, you'd have to look up endpoints, craft curl commands, and manually piece together workflows every time. The `/open-notebook` skill teaches Claude Code the complete API so you can say:

> *"Add these five ArXiv papers to a new notebook, run Key Insights on each one, then ask it to synthesize the main themes"*

...and Claude handles all the API calls, polling, and output formatting automatically.

### What the Skill Covers

| Feature | What Claude Can Do |
|---------|-------------------|
| **Notebooks** | Create, list, update, delete |
| **Sources** | Add URLs, YouTube, text, files — with async processing + status polling |
| **Chat** | Create sessions, send messages scoped to a notebook or global |
| **Insights** | Generate per-source AI analysis using 6 built-in transformation types |
| **Notes** | Create, update, save to Obsidian vault |
| **Podcasts** | Generate audio episodes (3 formats × 3 speaker styles), poll job status, download MP3 |
| **Search** | Cross-notebook semantic search |
| **Transformations** | Run any of the 6 built-in transforms on arbitrary text |

### Built-in Transformations

| ID | Name | Use |
|----|------|-----|
| `transformation:91k9npful3eaen8tjq5o` | Key Insights | Best for papers and articles |
| `transformation:2dkji8r5vm94uo5rci8t` | Dense Summary | Detailed compression |
| `transformation:52of6lkncba54509o2ak` | Simple Summary | Quick overview |
| `transformation:zz1291x7cak8leov6w22` | Paper Analysis | Academic paper breakdown |
| `transformation:7alaw5n2p7x036j2w80p` | Reflection Questions | Generate study questions |
| `transformation:mdkftnue4n52zi2ci12v` | Table of Contents | Structure extraction |

### Podcast Generation

Three episode profiles × three speaker styles:

| Profile | Style |
|---------|-------|
| `tech_discussion` | Two technical experts debating a topic |
| `solo_expert` | Single expert teaching a concept |
| `business_analysis` | Business panel discussing implications |

---

## The Self-Improving Loop

The `CLAUDE.md` file at the root of this vault is more than documentation — it's Claude's working memory for your research preferences.

After each research session, Claude appends a log entry documenting what worked, what it learned, and any new conventions to follow. Over time the file becomes a rich record of your research style, and Claude reads it at the start of each session to calibrate its approach:

```markdown
## Session Log

### 2026-03-24 — AI agent memory systems
- Deliverable: synthesis note + Key Insights per paper
- Papers used: 8 (5 ArXiv, 3 local database)
- Key finding: sparse attention dominates recent memory work
- What worked: local LLM interpretation added useful framing
- New convention: always check local database before ArXiv
```

The more you use the system, the more precisely it understands what you need.

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│                   Claude Code                    │
│         /skill or natural language intent        │
└───┬──────────┬──────────┬───────────┬────────────┘
    │          │          │           │
 /arxiv   /lancedb-  /ollama     /kestra
 /youtube  search    local LLMs  pipelines
 search
    │          │          │           │
    └──────────┴────┬─────┴───────────┘
                    │
         ┌──────────▼──────────┐
         │    /open-notebook   │
         │  localhost:5055     │
         │  Self-hosted        │
         │  100% private       │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   Obsidian Vault    │
         │  Markdown + Git     │
         │  Self-improving     │
         └─────────────────────┘
```

---

## Installation

### 1. Clone this vault
```bash
git clone https://github.com/not-qty/research-vault.git ~/research-vault
cd ~/research-vault
```

### 2. Run setup
```bash
chmod +x setup.sh && ./setup.sh
```

This installs `notebooklm-py`, `yt-dlp`, runs `notebooklm skill install`, and symlinks all vault skills into `~/.claude/skills/`.

### 3. Start Open Notebook

[Install Docker](https://docs.docker.com/get-docker/) then:

```bash
# Copy the compose file and start
mkdir -p ~/open-notebook && cp docker-compose-example.yml ~/open-notebook/docker-compose.yml
cd ~/open-notebook && docker compose up -d
```

Open http://localhost:8502 → Settings → Models → add your AI provider API key.

### 4. Authenticate NotebookLM (optional — for cloud skills)
```bash
notebooklm login
```

### 5. Open vault in Obsidian
Point [Obsidian](https://obsidian.md) at the vault folder. All research notes, session logs, and reports will appear as a linked graph.

---

## Usage Examples

```
# Full research pipeline on a topic
/research-pipeline "transformer attention mechanisms and memory"

# Find and load ArXiv papers into Open Notebook
/arxiv "find 10 recent papers on LLM agents"
/open-notebook create notebook "LLM Agent Research"
# → add found papers as sources

# Search locally-ingested paper database
/lancedb-search "social movements and collective behavior"

# YouTube research → podcast
/youtube-pipeline "top AI coding tools 2025" --deliverable podcast

# Ask a local LLM
/ollama "explain Bourdieu's concept of cultural capital"

# Trigger a data pipeline
/kestra trigger flow lancedb-ingest --input domain=sociology

# Quick chat with Open Notebook
/open-notebook ask "What are the main themes across my sources?"
```

---

## Requirements

| Tool | Version | Purpose |
|------|---------|---------|
| [Claude Code](https://claude.ai/code) | Latest | Skill execution environment |
| Python | 3.10+ | Skill command parsing |
| Docker | 20+ | Open Notebook |
| [notebooklm-py](https://github.com/teng-lin/notebooklm-py) | 0.3.4+ | Google NotebookLM skill |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Latest | YouTube search |
| [LanceDB](https://lancedb.github.io/lancedb/) | 0.29+ | Vector search skill |
| [Ollama](https://ollama.com) | Latest | Local LLM skill (optional) |
| [Kestra](https://kestra.io) | 1.3+ | Pipeline skill (optional) |

---

## Related Projects

- [Open Notebook](https://github.com/lfnovo/open-notebook) — the self-hosted research platform this vault is built around
- [notebooklm-py](https://github.com/teng-lin/notebooklm-py) — the Google NotebookLM Python client and Claude Code skill
- [Orchestrum](https://github.com/Optimal-Living-Systems/orchestrum) — multi-agent orchestration architecture

---

## License

MIT
