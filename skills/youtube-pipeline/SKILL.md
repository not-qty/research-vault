---
name: youtube-pipeline
description: Full research pipeline — searches YouTube, sends videos to NotebookLM, generates a deliverable, and saves results to the Obsidian vault. Use when asked to research a topic using YouTube and produce an output like an infographic, podcast, slides, or mind map.
---

# YouTube Research Pipeline

End-to-end research workflow: YouTube search → NotebookLM analysis → deliverable → Obsidian vault note.

## When This Skill Activates

**Explicit:** `/youtube-pipeline`

**Intent detection:**
- "Research X and make an infographic"
- "Find YouTube videos on X and create a podcast"
- "Build a NotebookLM notebook on X from YouTube"
- "Research X — what drives views, what are the gaps?"

## Workflow Steps

### Step 1: Search YouTube
Use the `youtube-search` skill to find relevant videos.

```bash
yt-dlp "ytsearch10:<topic>" --dump-json --flat-playlist --no-warnings 2>/dev/null
```

Select the best 5–10 videos based on:
- Relevance to topic
- View count (higher = more validated)
- Recency (prefer last 12 months unless topic is evergreen)
- Channel authority

### Step 2: Create NotebookLM Notebook

```bash
# Create notebook
notebooklm create "<topic-slug>"

# Use the notebook
notebooklm use "<notebook-id-or-name>"
```

### Step 3: Add YouTube Sources

```bash
# Add each video URL as a source
notebooklm source add "<youtube-url-1>"
notebooklm source add "<youtube-url-2>"
# ... repeat for each video
```

Wait for sources to process before generating (sources show as "ready" in `notebooklm source list`).

### Step 4: Generate Deliverable

Choose based on user request:

```bash
# Infographic
notebooklm generate infographic

# Audio Overview (podcast)
notebooklm generate audio --format deep-dive

# Slide Deck
notebooklm generate slides

# Mind Map
notebooklm generate mind-map

# Study Guide / Report
notebooklm generate report --format study-guide
```

### Step 5: Wait for Generation

```bash
notebooklm artifact list   # check status — wait until not "pending"
```

Retry `artifact list` every 30 seconds until status is complete.

### Step 6: Download Artifact

```bash
VAULT="$HOME/work/research-vault"
TOPIC_SLUG="<topic-slug>"
mkdir -p "$VAULT/YouTube/$TOPIC_SLUG"

notebooklm download <artifact-type> --output "$VAULT/YouTube/$TOPIC_SLUG/"
```

### Step 7: Save Research Note to Vault

Create `$VAULT/YouTube/<topic-slug>/README.md` using this template:

```markdown
# <Topic Title>

**Date:** YYYY-MM-DD
**Source type:** YouTube
**NotebookLM notebook:** <notebook-id>
**Deliverable:** <type> — saved to this folder

## Summary
<2-4 sentences from NotebookLM analysis>

## Key Findings
- <finding 1>
- <finding 2>
- <finding 3>

## What Drives Views
<if user asked — patterns across high-view videos>

## Gaps & Opportunities
<what the existing content misses>

## Sources

| Title | Channel | Views | URL |
|-------|---------|-------|-----|
| ... | ... | ... | ... |

## Analysis Notes
<deeper observations>
```

### Step 8: Update CLAUDE.md

Append to the Session Log in `$VAULT/CLAUDE.md`:

```markdown
### YYYY-MM-DD — <topic>
- Deliverable: <type>
- Videos used: <count>
- Key finding: <one sentence>
- What worked: <note>
- Preferences: <any new convention>
```

## Deliverable Types Reference

| Type | Command | Output Format |
|------|---------|--------------|
| Infographic | `generate infographic` | PNG |
| Podcast | `generate audio --format deep-dive` | MP3 |
| Brief audio | `generate audio --format brief` | MP3 |
| Slides | `generate slides` | PDF, PPTX |
| Mind map | `generate mind-map` | JSON |
| Study guide | `generate report --format study-guide` | Markdown |
| Briefing doc | `generate report --format briefing-doc` | Markdown |

## Error Handling

- **Auth error:** Run `notebooklm login` and retry
- **Source not ready:** Wait 30–60s and check `notebooklm source list` again
- **Generation timeout:** Check `notebooklm artifact list` — may still be processing
- **Rate limit:** Wait 5 minutes and retry

## Example Invocation

User: "Research the top MCP servers, what drives views, what are the gaps — give me an infographic"

1. Search: `ytsearch10:top MCP servers 2025`
2. Select top 8 by views + recency
3. Create notebook: `top-mcp-servers`
4. Add 8 YouTube URLs as sources
5. Generate: `notebooklm generate infographic`
6. Download to `YouTube/top-mcp-servers/infographic.png`
7. Save `YouTube/top-mcp-servers/README.md` with analysis
8. Update `CLAUDE.md` session log
