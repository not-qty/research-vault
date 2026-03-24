#!/usr/bin/env bash
# Bootstrap research-vault on a fresh machine
set -e

echo "==> Installing Python packages..."
pip install notebooklm-py yt-dlp --break-system-packages

echo "==> Installing notebooklm Claude Code skill..."
notebooklm skill install

echo "==> Symlinking vault skills into ~/.claude/skills/..."
mkdir -p ~/.claude/skills
VAULT_DIR="$(cd "$(dirname "$0")" && pwd)"

for skill in youtube-search youtube-pipeline; do
  TARGET="$HOME/.claude/skills/$skill"
  if [ -L "$TARGET" ]; then
    echo "  $skill already symlinked, skipping"
  elif [ -d "$TARGET" ]; then
    echo "  WARNING: $TARGET exists as a real dir, skipping"
  else
    ln -s "$VAULT_DIR/skills/$skill" "$TARGET"
    echo "  linked $skill"
  fi
done

echo ""
echo "==> NEXT STEP: Authenticate with NotebookLM"
echo "    Run: notebooklm login"
echo "    Then: notebooklm list"
echo ""
echo "Done! Vault is ready at: $VAULT_DIR"
