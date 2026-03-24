---
name: youtube-search
description: Search YouTube and return structured video results using yt-dlp. Use when asked to search YouTube, find videos about a topic, or gather YouTube sources for research.
---

# YouTube Search

Search YouTube for videos by query and return structured results.

## When This Skill Activates

**Explicit:** User says `/youtube-search`, "search YouTube for...", "find YouTube videos about..."

**Intent detection:**
- "What YouTube videos cover X?"
- "Find me videos on X"
- "Search YouTube for X"
- "Look up X on YouTube"

## Usage

```bash
# Basic search — returns top 10 results as JSON
yt-dlp "ytsearch10:<query>" --dump-json --flat-playlist --no-warnings 2>/dev/null

# Fewer results
yt-dlp "ytsearch5:<query>" --dump-json --flat-playlist --no-warnings 2>/dev/null
```

## Output Format

Parse the JSON and present results as a structured table:

| # | Title | Channel | Views | Duration | URL |
|---|-------|---------|-------|----------|-----|
| 1 | ... | ... | ... | ... | ... |

Then list full URLs for use as NotebookLM sources:
```
URLs for NotebookLM:
1. https://www.youtube.com/watch?v=<id>
2. ...
```

## Key JSON Fields

| Field | Description |
|-------|-------------|
| `title` | Video title |
| `uploader` | Channel name |
| `view_count` | View count (integer) |
| `duration_string` | Human-readable duration |
| `webpage_url` | Full YouTube URL |
| `description` | Video description (first 200 chars useful) |
| `upload_date` | YYYYMMDD format |

## Example

User: "search YouTube for top MCP servers"

```bash
yt-dlp "ytsearch10:top MCP servers" --dump-json --flat-playlist --no-warnings 2>/dev/null | \
  python3 -c "
import sys, json
for line in sys.stdin:
    try:
        v = json.loads(line.strip())
        print(f\"{v.get('title','')} | {v.get('uploader','')} | {v.get('view_count',0):,} views | {v.get('duration_string','')} | {v.get('webpage_url','')}\")
    except: pass
"
```

## Notes

- yt-dlp does NOT download video — `--dump-json` only fetches metadata
- `--flat-playlist` keeps it fast (no extra lookups)
- `--no-warnings` keeps output clean for parsing
- Rate limit: avoid more than 50 searches per hour
- If a video is age-restricted or unavailable, yt-dlp will skip it silently
