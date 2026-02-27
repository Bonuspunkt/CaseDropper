#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="/workspaces/${1}/.claude"

sudo chown -R vscode:vscode /home/vscode/.claude "$CLAUDE_DIR"

# Install Zig
ZIG_VERSION=0.15.2
ZIG_ARCH=$(uname -m)
if ! command -v zig &>/dev/null; then
  curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz
  tar xf /tmp/zig.tar.xz -C /tmp
  sudo mv "/tmp/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}/zig" /usr/local/bin/
  sudo mv "/tmp/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}/lib" /usr/local/lib/zig
  rm -rf /tmp/zig*
fi

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
