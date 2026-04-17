# OpenClaw + QMD: New Machine Setup Guide

> This guide documents exactly how to reproduce the current OpenClaw + QMD setup on a fresh machine.
> It reflects the real configuration as of April 2026 on a WSL2 + Windows machine with an RTX 4090.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Install Bun](#2-install-bun)
3. [Install OpenClaw](#3-install-openclaw)
4. [Install QMD](#4-install-qmd)
5. [Restore QMD Collections](#5-restore-qmd-collections)
6. [Download the Right Models](#6-download-the-right-models)
7. [Index Everything](#7-index-everything)
8. [Configure OpenClaw to Use QMD](#8-configure-openclaw-to-use-qmd)
9. [Restore the Rest of openclaw.json](#9-restore-the-rest-of-opencloawjson)
10. [Verify Everything Works](#10-verify-everything-works)
11. [Backup Strategy](#11-backup-strategy)

---

## 1. Prerequisites

Before anything else, make sure the following are in place:

- **WSL2** is installed and your distro is Ubuntu (or equivalent)
- **Windows iCloud Drive** is synced and accessible at the expected path (see Step 5 for the Obsidian collection path)
- **CUDA drivers** are installed if you want GPU acceleration for QMD's local models (RTX 4090 on this machine — CUDA offloading dramatically speeds up embedding and query expansion)
- **Git** is available: `sudo apt install git`
- **curl** is available: `sudo apt install curl`

Check GPU visibility in WSL2:

```bash
nvidia-smi
```

If that works, CUDA offloading will be picked up by QMD automatically.

---

## 2. Install Bun

Both OpenClaw and QMD are installed via Bun. Install it first:

```bash
curl -fsSL https://bun.sh/install | bash
```

Then reload your shell or source your profile:

```bash
source ~/.zshrc   # or ~/.bashrc depending on your shell
```

Verify:

```bash
bun --version
# Expected: 1.3.11 or newer
```

---

## 3. Install OpenClaw

```bash
bun install -g openclaw
```

Verify:

```bash
openclaw --version
```

Run the setup wizard to initialize the config:

```bash
openclaw setup
```

This creates `~/.openclaw/openclaw.json` with defaults. You will overwrite most of it in Step 8 and Step 9, but running the wizard first ensures the directory structure is created correctly.

If you have a backup of `~/.openclaw/` (see [Backup Strategy](#11-backup-strategy)), you can restore it now and skip most of the remaining config steps. Still read the guide to verify paths are correct for the new machine.

---

## 4. Install QMD

QMD is the memory backend — a local-first hybrid search engine with reranking and query expansion.

```bash
bun install -g @tobilu/qmd
```

Make sure `qmd` is on your PATH. If Bun's global bin isn't in PATH by default, add it:

```bash
# In ~/.zshrc or ~/.bashrc
export PATH="$HOME/.bun/bin:$PATH"
```

Verify:

```bash
qmd --version
# Expected: 2.0.1 or newer
```

Check that the index storage location resolves correctly:

```bash
qmd status
# Should show: Index: /home/<you>/.cache/qmd/index.sqlite
```

**Why `~/.cache/qmd`?**
QMD uses `XDG_CACHE_HOME` to determine where it stores its index and models. If `XDG_CACHE_HOME` is unset (the default), it falls back to `~/.cache`. This means both your system `qmd` CLI and OpenClaw's QMD backend share the same index at `~/.cache/qmd/index.sqlite` — one location to back up and restore.

If your `XDG_CACHE_HOME` is set to something custom, QMD will use `$XDG_CACHE_HOME/qmd/` instead. Keep this consistent across machines.

---

## 5. Restore QMD Collections

Collections are not stored in the index file — they are configuration that tells QMD which directories to watch and index. You must re-add them manually on a new machine.

Current collections on this setup:

### `workspace` — OpenClaw workspace markdown files

```bash
qmd collection add workspace /home/parikshit/.openclaw/workspace --pattern "**/*.md"
```

> On a new machine, replace `parikshit` with your Linux username.

### `sessions` — Exported session transcripts

```bash
qmd collection add sessions /home/parikshit/.openclaw/workspace/sessions-export --pattern "**/*.md"
```

> Same username substitution applies.

### `notes` — Personal notes directory

```bash
qmd collection add notes /home/parikshit/notes --pattern "**/*.md"
```

> This is a local directory. Make sure it exists or restore it from backup before adding.

### `obsidian` — Obsidian vault via Windows iCloud Drive

```bash
qmd collection add obsidian "/mnt/c/Users/tiwar/iCloudDrive/iCloud~md~obsidian/Second Brain" --pattern "**/*.md"
```

> **Important:** This path depends on:
> 1. Your Windows username (`tiwar` in this case — double-check on the new machine)
> 2. iCloud Drive being fully synced before you run `qmd update`
> 3. The WSL2 mount for the C: drive being at `/mnt/c/` (standard, but verify with `ls /mnt/c/Users/`)
>
> If iCloud hasn't synced yet, the path will exist but the vault will be empty or incomplete. Wait for full sync before indexing.

### Verify collections were added

```bash
qmd collection list
```

Expected output:
```
Collections (4):
  notes       → /home/parikshit/notes
  workspace   → /home/parikshit/.openclaw/workspace
  obsidian    → /mnt/c/Users/tiwar/iCloudDrive/iCloud~md~obsidian/Second Brain
  sessions    → /home/parikshit/.openclaw/workspace/sessions-export
```

---

## 6. Download the Right Models

QMD uses three local GGUF models. They are downloaded automatically on first use, but each is triggered by a different command. Here is how to download them intentionally in one shot so you are not surprised mid-session.

### Where models are stored

```
~/.cache/qmd/models/
```

### Model 1 — Embedding model (for vector search)

**Source:** `https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF`
**File:** `hf_ggml-org_embeddinggemma-300M-Q8_0.gguf`
**Size:** ~314 MB
**Triggered by:** `qmd embed` or `qmd update`

To trigger immediately:

```bash
qmd embed
```

This embeds any unembedded documents. On a fresh install with no documents yet indexed, add a collection first (Step 5), run `qmd update`, then `qmd embed`.

### Model 2 — Query expansion / generation model (for hybrid search)

**Source:** `https://huggingface.co/tobil/qmd-query-expansion-1.7B-gguf`
**File:** `hf_tobil_qmd-query-expansion-1.7B-q4_k_m.gguf`
**Size:** ~1.28 GB
**Triggered by:** `qmd query "anything"`

To trigger immediately:

```bash
qmd query "test"
```

This will start downloading the model in the foreground. Let it complete — do not interrupt. It only downloads once.

### Model 3 — Reranker (for result reranking)

**Source:** `https://huggingface.co/ggml-org/Qwen3-Reranker-0.6B-Q8_0-GGUF`
**File:** downloaded automatically when reranking is first invoked
**Size:** ~600 MB (estimate)
**Triggered by:** `qmd query "anything"` (same command as above, runs after query expansion model is ready)

### Summary: download all models at once

Run these two commands after collections are set up and `qmd update` has been run:

```bash
# Step 1: index files + download embedding model
qmd update && qmd embed

# Step 2: download query expansion + reranker models (will block until done)
qmd query "test warm-up query"
```

**With an RTX 4090 and CUDA:** all three models offload to GPU automatically. QMD detects CUDA and sets `offloading: yes`. No extra configuration needed.

**Without a GPU:** models run on CPU (12 math cores on this machine). Everything still works — embedding and querying will just be slower, especially the first few calls while models load into memory.

### Verify models are present

```bash
ls -lh ~/.cache/qmd/models/
```

You should see all three model files with no `.ipull` extension (`.ipull` means a download is still in progress).

---

## 7. Index Everything

Once collections are added and models are downloaded, index all your content:

```bash
# Pull latest from git-backed collections (if applicable)
qmd update --pull

# Run a full re-embed pass for any pending vectors
qmd embed
```

Check the result:

```bash
qmd status
```

Look for `Pending: 0 need embedding`. If the number is non-zero, run `qmd embed` again.

On this machine the full index is ~51 MB with 465 files and 4,875 embedded chunks. Your numbers will vary depending on how much content is in your collections at restore time.

---

## 8. Configure OpenClaw to Use QMD

> **Note:** The `memory.backend` field documented on the OpenClaw docs site is **not yet valid** in OpenClaw 2026.3.30 — adding it causes a config validation error on startup ("Unrecognized key: memory"). QMD is invoked directly by the agent via `qmd` CLI commands rather than through a backend config key. Skip this step and use QMD via agent instructions in `HEARTBEAT.md` and `AGENTS.md` instead.

The `memorySearch` block (local SQLite + Cohere embeddings) remains the active in-process search backend. QMD operates alongside it as an agent-callable tool.

Full `agents.defaults` section for reference:

```json
"agents": {
  "defaults": {
    "model": { ... },
    "workspace": "/home/parikshit/.openclaw/workspace",
    "memorySearch": {
      "provider": "local",
      "model": "us.cohere.embed-v4:0"
    },
    "compaction": {
      "memoryFlush": {
        "enabled": true,
        "softThresholdTokens": 4000
      }
    },
    "contextPruning": {
      "mode": "cache-ttl",
      "ttl": "1h",
      "keepLastAssistants": 3
    },
    "heartbeat": {
      "lightContext": true,
      "model": "ollama/llama3.2:1b",
      "activeHours": {
        "start": "08:00",
        "end": "23:00"
      }
    }
  }
}
```

---

## 9. Restore the Rest of openclaw.json

Other sections of `openclaw.json` to restore (either from backup or by re-entering values):

### Amazon Bedrock (AI model provider)

```json
"models": {
  "providers": {
    "amazon-bedrock": {
      "baseUrl": "https://bedrock-runtime.us-west-2.amazonaws.com",
      "auth": "aws-sdk",
      "api": "bedrock-converse-stream",
      "models": [ ... ]
    }
  }
}
```

Make sure `~/.aws/credentials` or the AWS SDK environment variables are configured so Bedrock auth works. Test with:

```bash
aws sts get-caller-identity
```

### Browser (Chromium via snap)

```json
"browser": {
  "enabled": true,
  "executablePath": "/snap/bin/chromium",
  "headless": true,
  "noSandbox": true,
  "attachOnly": true,
  "defaultProfile": "wslg"
}
```

Install Chromium if not present:

```bash
sudo snap install chromium
```

Verify the path:

```bash
ls /snap/bin/chromium
```

### Gateway auth token

The `gateway.auth.token` in `openclaw.json` is a secret. Restore it from your backup or 1Password — do not hardcode it in this file or commit it to git.

### Discord / WhatsApp tokens

Same rule: restore bot tokens from a secret manager, not from plain text in the repo.

---

## 10. Verify Everything Works

Run through this checklist in order:

```bash
# 1. QMD index is healthy
qmd status

# 2. All collections are present
qmd collection list

# 3. BM25 search returns results immediately (no model needed)
qmd search "recent decisions"

# 4. Hybrid search works (requires all models to be downloaded)
qmd query "recent decisions"

# 5. OpenClaw can start
openclaw start

# 6. OpenClaw memory backend is QMD (check logs or run a memory search from agent)
# In an agent session, the agent should be able to call qmd query automatically
```

If `qmd query` hangs on the first run, a model is still downloading. Check:

```bash
ls -lh ~/.cache/qmd/models/
# Any file ending in .ipull is still in progress — wait for it to complete
```

---

## 11. Backup Strategy

Everything that matters lives in two places. Back up both.

### What to back up

| Location | What it contains | Size (approx) |
|---|---|---|
| `~/.openclaw/` | Workspace files, memory, agent configs, session exports | Variable |
| `~/.cache/qmd/` | Index SQLite + downloaded models | 51 MB index + ~2 GB models |

The models in `~/.cache/qmd/models/` are large but re-downloadable. If bandwidth is cheap, exclude them from backup and just re-run the warm-up commands on the new machine. If bandwidth is limited, include them to avoid the ~2 GB download.

### Minimal backup (index + config only, re-download models)

```bash
# Back up
tar -czf openclaw-backup.tar.gz ~/.openclaw/ ~/.cache/qmd/index.sqlite

# Restore on new machine
tar -xzf openclaw-backup.tar.gz -C ~/
```

Then re-run `qmd update && qmd embed && qmd query "warm-up"` to re-download the models.

### Full backup (include models, no re-download needed)

```bash
# Back up
tar -czf openclaw-full-backup.tar.gz ~/.openclaw/ ~/.cache/qmd/

# Restore on new machine
tar -xzf openclaw-full-backup.tar.gz -C ~/
```

### What is NOT in the backup

- **QMD collections config** — collection paths are stored in the SQLite index, so they ARE included in the backup. However, verify on the new machine that all paths resolve correctly (especially the Obsidian iCloud path and any paths with your Linux username).
- **AWS credentials** — store in `~/.aws/credentials` separately or use IAM roles
- **Bot tokens (Discord, WhatsApp)** — store in a secret manager
- **`openclaw.json` gateway token** — restore from secret manager

### After restoring the backup on a new machine

```bash
# 1. Verify collections point to valid paths
qmd collection list

# 2. If any path has changed (e.g. username or Windows mount point), remove and re-add:
qmd collection remove <name>
qmd collection add <name> /new/path --pattern "**/*.md"

# 3. Re-index to pick up any changes since the backup
qmd update

# 4. If models were not backed up, re-download them
qmd embed              # triggers embedding model download
qmd query "warm-up"   # triggers query expansion + reranker download
```

---

*Last updated: April 2026 — WSL2, Ubuntu, RTX 4090, Bun 1.3.11, QMD 2.0.1, OpenClaw 2026.3.30*
