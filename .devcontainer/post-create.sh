#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="/workspaces/${1}/.claude"

sudo chown -R vscode:vscode /home/vscode/.claude "$CLAUDE_DIR"

# Seed settings.local.json if it doesn't exist yet
if [ ! -f "$CLAUDE_DIR/settings.local.json" ]; then
  cat > "$CLAUDE_DIR/settings.local.json" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "Read(*)",
      "WebFetch(*)",
      "WebSearch(*)",
      "Write(*)",
      "mcp__playwright__*"
    ],
    "deny": []
  }
}
EOF
fi
