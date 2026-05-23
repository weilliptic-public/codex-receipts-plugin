# Weilliptic Receipts — Codex Plugin

AI code provenance on [WeilChain](https://marauder.weilliptic.ai/dashboard). Every AI-generated code change is cryptographically receipted and persisted on-chain for audit, compliance, and knowledge reuse.

## Install

**One-line install:**

```bash
curl -fsSL https://raw.githubusercontent.com/weilliptic-public/codex-receipts-plugin/main/install.sh | bash
```

**Or clone and install locally:**

```bash
git clone https://github.com/weilliptic-public/codex-receipts-plugin.git
cd codex-receipts-plugin
./install.sh
```

Then start Codex and trust the hooks when prompted.

## Prerequisites

- A Weilliptic wallet export file (`.wc` format)
- Set the environment variable:
  ```bash
  export WEILLIPTIC_ACCOUNT_FILE="/path/to/your/wallet.wc"
  ```

## What It Does

Every time Codex writes or edits a file:

1. **PreToolUse** — checks your token balance (blocks if exhausted)
2. **PostToolUse** — builds a TraceRecord with exact line ranges, uploads to cloud storage, posts receipt hash on-chain, debits tokens
3. **Stop** — links the prompt to its receipts for semantic search
4. **git commit** — consolidates all receipts under the commit hash on-chain

## Viewing Receipts

Open the [Weilliptic block explorer](https://marauder.weilliptic.ai/dashboard) or the [Codensics](https://codensics.weilliptic.ai) dashboard to view receipted changes, session transcripts, and similar prompts.

## Hooks

| Event | Purpose |
|---|---|
| SessionStart | Install git post-commit hook, clear stale prompts |
| UserPromptSubmit | Cache prompt for later linkage |
| PreToolUse | Balance gating (free-tier cap / org token balance) |
| PostToolUse | Receipt creation (TraceRecord → cloud storage → on-chain) |
| Stop | Collect receipts, write prompt + receipts to `.prompts` |

## Skills

- `/install-git-hooks` — manually install the git post-commit hook

## License

Proprietary — Copyright (c) Weilliptic Inc. All rights reserved.
