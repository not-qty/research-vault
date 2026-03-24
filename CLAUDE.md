# Research Vault — Claude.md

This is the "brain within a brain" for Claude Code operating in this research vault.
Update this file after each research session to reflect new preferences, conventions, and learnings.

---

## Vault Layout

| Folder | Purpose |
|--------|---------|
| `Research/` | Deep-dive notes on any topic |
| `YouTube/` | YouTube pipeline outputs (one subfolder per topic) |
| `skills/` | Claude Code skill definitions (version-controlled) |

---

## Note Format

Every research note follows this structure:

```markdown
# <Topic Title>

**Date:** YYYY-MM-DD
**Source type:** YouTube / Article / PDF / Mixed
**Deliverable:** infographic / podcast / slides / mind-map / none

## Summary
2–4 sentence overview of the key takeaway.

## Key Findings
- Finding 1
- Finding 2
- Finding 3

## Sources
- [[Source Title]] — <URL>
- [[Source Title]] — <URL>

## Analysis
Deeper observations, patterns, gaps, opportunities.

## Next Steps
- [ ] Follow-up question or action
```

---

## Wikilinks

Always use `[[Note Name]]` to cross-reference notes. Link generously — the graph is a feature.

---

## Research Preferences

- **Depth over breadth** — fewer, richer notes beat many shallow ones
- **Gaps and opportunities** — always call out what the sources miss
- **Plain language** — avoid jargon unless the topic demands it
- **Concrete examples** — abstract findings need at least one real example

---

## YouTube Pipeline Conventions

- Notebook name = topic slug (e.g., `top-mcp-servers-2026`)
- Save artifacts to `YouTube/<topic-slug>/`
- Always include view count and channel in source list
- Note the date — YouTube trends move fast

---

## Self-Update Instructions

After each research session, append a dated log entry at the bottom of this file:

```
## Session Log

### YYYY-MM-DD — <topic>
- What worked well
- What to do differently next time
- Any new convention added
```

---

## Session Log

### 2026-03-24 — vault initialized
- Created research-vault on /lab storage
- Linked to GitHub repo not-qty/research-vault
- Skills: youtube-search, youtube-pipeline installed

### 2026-03-24 — Full research infrastructure setup
- Built: research-vault, 9 CC skills, Open Notebook, desktop launchers
- Skills installed: youtube-search, youtube-pipeline, open-notebook, ollama, lancedb-search, kestra, arxiv, research-pipeline + notebooklm
- Apps added: Obsidian v1.12.7, ChatKeeper v2026.03.046, Open Notebook (Docker)
- GitHub: not-qty/research-vault (public), OLS ols-ai-lab-setup (session report)
- What worked: building skills from live API exploration, extracting icons from AppImages
- Open items: notebooklm login needed, Open Notebook model config needed at localhost:8502
