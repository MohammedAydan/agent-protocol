# Security notes (Agent Protocol 1.0.0)

## Install surface

- `init.sh` only writes protocol-owned paths: `AGENTS.md`, optional `CLAUDE.md`/`GEMINI.md`, `.agents/`, `adapters/`, selected harness mirrors, `plans/` brain files.
- **Never** overwrites application `README.md`, source trees, `package.json`, lockfiles, or `.git/`.
- `--force` refreshes protocol-owned files only.
- Refuses system paths (`/`, `/usr`, `/etc`, …).

## Remote install (`install-remote.sh`)

- HTTPS only; default allowlist `https://github.com/…` and `https://codeload.github.com/…`.
- Downloads archive to a temp directory, validates `AGENTS.md` + `init.sh` exist, then runs local `init.sh`.
- Prefer a **pinned tag** (`v1.0.0`). Default repo: `MohammedAydan/agent-protocol`.
- Prefer `git clone` + review when possible instead of piping `curl | bash`.

## Runtime scripts

- Plain bash; no network calls except `install-remote.sh`.
- No execution of project application code.
- Task/plan scripts only edit markdown under `plans/` and protocol paths.
- Agents are instructed never to invent secrets or write `.env` / keystores.

## Reporting

If you find an issue, treat protocol scripts as trusted tooling in your supply chain: pin versions, review diffs on `--force` upgrades.
