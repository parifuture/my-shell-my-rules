# Claude Code Global Install Log

This is an append-only log of globally installed MCP servers, plugins, skills, and other Claude Code configuration changes. Any Claude session that modifies `~/.claude/settings.json` should add an entry here.

## MCP Servers

| Date | Name | Purpose | Triggered from | Added by |
|------|------|---------|----------------|----------|
| 2026-04-12 | pmll-memory-mcp | Token-saving session cache for jCodemunch results | my-shell-my-rules | Pari |
| 2026-04-12 | linear | Official Linear MCP server (mcp.linear.app) for issue/project management | my-shell-my-rules | Claude |
| 2026-04-14 | pencil | Pencil design editor MCP — read/write .pen files, design generation/validation | division-2-builds | Pari |

## Skills

| Date | Name | Purpose | Triggered from | Added by |
|------|------|---------|----------------|----------|
| 2026-04-12 | linear | Manage Linear issues/projects (git clone, API key via 1Password) | my-shell-my-rules | Claude |
| 2026-04-12 | quien | Domain lookups: WHOIS, DNS, mail, SSL, HTTP, tech stack, SEO (via `npx skills add retlehs/quien`) | my-shell-my-rules | Claude |

## Plugins

| Date | Name | Purpose | Triggered from | Added by |
|------|------|---------|----------------|----------|
| 2026-04-12 | sentrux@sentrux-marketplace | Code structural health scanning (A-F grades) | my-shell-my-rules | Pari |
| 2026-04-12 | dev-workflow@unimatrix-forge | UI design, diagrams, GitLab CLI skills | my-shell-my-rules | Pari |
| 2026-04-12 | superpowers@claude-plugins-official | Brainstorming, TDD, debugging, plans, code review workflows | my-shell-my-rules | Pari |
| 2026-04-12 | vercel@claude-plugins-official | Vercel deployment, AI SDK, Next.js guidance | my-shell-my-rules | Pari |

## Hooks

| Date | Hook | Purpose | Triggered from | Added by |
|------|------|---------|----------------|----------|
| 2026-04-12 | jcodemunch-mcp (PreToolUse, PostToolUse, PreCompact, Worktree) | Auto-index on file edits, worktree lifecycle | my-shell-my-rules | Pari |

## Other Changes

| Date | Change | Purpose | Triggered from | Added by |
|------|--------|---------|----------------|----------|
| 2026-04-12 | statusLine → context-bar.sh | Two-line Eldritch-themed status bar | my-shell-my-rules | Pari |
| 2026-04-12 | autoUpdatesChannel → latest | Stay on latest Claude Code release | my-shell-my-rules | Pari |
| 2026-04-13 | pi-coding-agent (npm global) | Terminal coding agent on AWS Bedrock via backstage-prd static IAM keys; `pib` wrapper in zshrc-macos.sh | my-shell-my-rules | Claude |
| 2026-04-13 | pi subagent extension + agents (scout/planner/reviewer/worker) | Isolated-context sub-agents for pi, all pinned to us.anthropic.claude-sonnet-4-6; dotfiles at pi/, symlinked into ~/.pi/agent/ | my-shell-my-rules | Claude |
| 2026-04-13 | 1password.md — session caching rule | Read each secret once per Claude session, cache in conversation context to stop TouchID spam | my-shell-my-rules | Claude |
| 2026-04-13 | pi: removed vendored subagent extension + workflow prompts; renamed agents with -pari suffix | Resolved tool-name conflict with @ifi/pi-extension-subagents. Dotfiles now contain only the four `-pari`-suffixed agents (Bedrock-pinned); ifi's builtins own scout/planner/reviewer/worker. Also removed workflow prompts that referenced the unsuffixed names. | my-shell-my-rules | Claude |
| 2026-04-13 | pi: shadow pi binary with zsh function auto-loading bedrock profile | `pi()` function in zshrc-macos.sh transparently loads `awsp bedrock` and passes Bedrock `--provider/--model` flags; package subcommands (install/remove/update/list/config) pass through unmodified | my-shell-my-rules | Claude |
