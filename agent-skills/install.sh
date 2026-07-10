#!/usr/bin/env bash
#
# Installs the SmartCoach agent skill for Claude Code / Claude.
#
# Assembles a self-contained skill folder (SKILL.md + recipes/) from this repo into
# the install location. The recipes are the neutral source of truth; SKILL.md is the
# thin Claude adapter — both are copied together so the installed skill stands alone.
#
# Usage:
#   ./install.sh                 # install for the current user (Claude Code config dir)
#   ./install.sh <project-dir>   # install into a project (<project-dir>/.claude/skills)
#
# User-level installs honor CLAUDE_CONFIG_DIR (Claude Code's config-dir override);
# they fall back to ~/.claude when it is unset. Requires Claude Code on macOS/Linux.
# (Claude.ai / Claude Desktop users upload the skill folder via the UI instead.)
#
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ge 1 ]]; then
  case "$1" in
    *.xcodeproj|*.xcworkspace)
      echo "error: pass the project FOLDER, not the Xcode project bundle." >&2
      echo "       e.g.  ./install.sh ${1%/*}" >&2
      exit 1
      ;;
  esac
  DEST_ROOT="$1/.claude/skills"
else
  DEST_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
fi

DEST="$DEST_ROOT/smartcoach"

# Verify we can create/write the destination before touching anything.
if ! mkdir -p "$DEST/recipes" 2>/dev/null; then
  echo "error: cannot create destination: $DEST" >&2
  echo "       check permissions, or set CLAUDE_CONFIG_DIR to a writable Claude config dir." >&2
  exit 1
fi
if [[ ! -w "$DEST" ]]; then
  echo "error: destination is not writable: $DEST" >&2
  exit 1
fi

# Verify the source files are present (guards against a partial/corrupt download).
if [[ ! -f "$SRC_DIR/claude/smartcoach/SKILL.md" ]]; then
  echo "error: SKILL.md not found next to install.sh (expected $SRC_DIR/claude/smartcoach/SKILL.md)" >&2
  exit 1
fi

cp "$SRC_DIR/claude/smartcoach/SKILL.md" "$DEST/SKILL.md"
cp "$SRC_DIR/recipes/"*.md "$DEST/recipes/"

echo "Installed SmartCoach skill to: $DEST"
echo "Contents:"
find "$DEST" -type f | sed "s|$DEST/|  |"
echo "Restart your Claude Code session to pick up the skill."
