# Install Agent Protocol

**Repository:** https://github.com/MohammedAydan/agent-protocol

## One-liner (into current project)

```bash
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/v1.0.0/install-remote.sh \
  | bash -s -- --here --adapters all --non-interactive
```

From `main` branch:

```bash
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.sh \
  | bash -s -- --here --adapters all --non-interactive
```

## Choose harnesses

```bash
# Interactive menu
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/v1.0.0/install-remote.sh \
  | bash -s -- --here

# Claude + Cursor only
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/v1.0.0/install-remote.sh \
  | bash -s -- --here --adapters claude,cursor --non-interactive

# AGENTS.md only (no tool-specific files)
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/v1.0.0/install-remote.sh \
  | bash -s -- --here --adapters none --non-interactive
```

## Local clone (safest)

```bash
git clone --depth 1 --branch v1.0.0 https://github.com/MohammedAydan/agent-protocol.git /tmp/agent-protocol
cd /path/to/your-app
bash /tmp/agent-protocol/init --here --adapters all
```

## What is never touched

Your `README.md`, application source, `package.json`, and `.git/` are **not** modified.

Only protocol paths are added: `AGENTS.md`, `.agents/`, `adapters/`, `plans/`, and selected harness mirrors.

## After install

```bash
bash .agents/scripts/resume.sh
bash .agents/scripts/protocol.sh new T1 first-feature
```
