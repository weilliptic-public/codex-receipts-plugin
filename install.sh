#!/bin/bash
#
# Weilliptic Receipts — Codex Plugin Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/weilliptic-public/codex-receipts-plugin/main/install.sh | bash
#
# Or clone and run locally:
#   git clone https://github.com/weilliptic-public/codex-receipts-plugin.git
#   cd codex-receipts-plugin && ./install.sh
#
# Prerequisites:
#   - Codex CLI installed (npm install -g @openai/codex)
#   - WEILLIPTIC_ACCOUNT_FILE environment variable set to your wallet .wc file path
#
# What this does:
#   1. Downloads (or copies) plugin binaries to ~/.codex/plugins/weilliptic-receipts/
#   2. Creates hooks config at ~/.codex/hooks.json
#   3. Verifies the installation

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PLUGIN_DIR="$HOME/.codex/plugins/weilliptic-receipts"
HOOKS_FILE="$HOME/.codex/hooks.json"
REPO_URL="https://github.com/weilliptic-public/codex-receipts-plugin"

echo ""
echo "============================================="
echo "  Weilliptic Receipts — Codex Plugin Install"
echo "============================================="
echo ""

# Check if WEILLIPTIC_ACCOUNT_FILE is set
if [ -z "$WEILLIPTIC_ACCOUNT_FILE" ]; then
    echo -e "${RED}Warning:${NC} WEILLIPTIC_ACCOUNT_FILE is not set."
    echo "  Add to your shell profile (~/.zshrc or ~/.bashrc):"
    echo "    export WEILLIPTIC_ACCOUNT_FILE=\"/path/to/your/wallet.wc\""
    echo ""
fi

# Determine if running from cloned repo or via curl
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo "")"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/codex-audit-hook" ]; then
    echo "Installing from local directory: $SCRIPT_DIR"
    SOURCE_DIR="$SCRIPT_DIR"
else
    echo "Downloading plugin from GitHub..."
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 "$REPO_URL.git" "$TEMP_DIR" 2>/dev/null
    SOURCE_DIR="$TEMP_DIR"
fi

# Create plugin directory
echo "Installing binaries to $PLUGIN_DIR/bin/"
mkdir -p "$PLUGIN_DIR/bin"

# Copy binaries
for bin in codex-audit-hook codex-pretooluse-hook codex-session-start-hook codex-session-end-hook codex-stop-hook codex-user-prompt-submit-hook git-commit-hook; do
    if [ -f "$SOURCE_DIR/bin/$bin" ]; then
        cp "$SOURCE_DIR/bin/$bin" "$PLUGIN_DIR/bin/"
        chmod +x "$PLUGIN_DIR/bin/$bin"
    else
        echo -e "${RED}Warning:${NC} $bin not found in source"
    fi
done

# Copy hooks config
mkdir -p "$PLUGIN_DIR/hooks"
cp "$SOURCE_DIR/hooks/hooks.json" "$PLUGIN_DIR/hooks/"

# Copy skills
if [ -d "$SOURCE_DIR/skills" ]; then
    cp -R "$SOURCE_DIR/skills" "$PLUGIN_DIR/"
fi

# Create ~/.codex/hooks.json that points to the installed plugin
# Use the plugin directory as the base for binary paths
cat > "$HOOKS_FILE" << EOF
{
    "hooks": {
        "SessionStart": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "$PLUGIN_DIR/bin/codex-session-start-hook \$WEILLIPTIC_ACCOUNT_FILE",
                        "timeout": 30
                    }
                ]
            }
        ],
        "UserPromptSubmit": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "$PLUGIN_DIR/bin/codex-user-prompt-submit-hook"
                    }
                ]
            }
        ],
        "PreToolUse": [
            {
                "matcher": "^(Bash|apply_patch)$",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$PLUGIN_DIR/bin/codex-pretooluse-hook \$WEILLIPTIC_ACCOUNT_FILE",
                        "timeout": 30,
                        "statusMessage": "Checking token balance"
                    }
                ]
            }
        ],
        "PostToolUse": [
            {
                "matcher": "^(Bash|apply_patch)$",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$PLUGIN_DIR/bin/codex-audit-hook \$WEILLIPTIC_ACCOUNT_FILE",
                        "timeout": 120,
                        "statusMessage": "Recording AI provenance receipt"
                    }
                ]
            }
        ],
        "Stop": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "$PLUGIN_DIR/bin/codex-stop-hook \$WEILLIPTIC_ACCOUNT_FILE"
                    }
                ]
            }
        ]
    }
}
EOF

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "  Plugin:  $PLUGIN_DIR"
echo "  Hooks:   $HOOKS_FILE"
echo ""
echo "  Binaries installed:"
ls "$PLUGIN_DIR/bin/" | sed 's/^/    /'
echo ""
echo "  Next steps:"
echo "    1. Set your wallet path (if not already done):"
echo "       export WEILLIPTIC_ACCOUNT_FILE=\"/path/to/wallet.wc\""
echo ""
echo "    2. Start Codex and trust the hooks when prompted:"
echo "       codex"
echo ""
echo "    3. Verify hooks are loaded:"
echo "       /hooks"
echo ""
echo "============================================="

# Cleanup temp dir if used
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi
