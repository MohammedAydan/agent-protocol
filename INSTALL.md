# Install

**Repo:** https://github.com/MohammedAydan/agent-protocol

## Windows (PowerShell) — تفاعلي

من مجلد مشروعك:

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

سيظهر **قائمة** تختار منها:

| إدخال | المعنى |
|--------|--------|
| `2` أو Enter | **None** — `AGENTS.md` فقط (أنظف خيار) |
| `1` | كل الـ harnesses |
| `3` | Claude فقط |
| `4` | Cursor فقط |
| `3,4` | Claude + Cursor |
| `claude,cursor` | نفس الشيء بالأسماء |
| `11` | قائمة مخصصة |

### اختصارات بدون قائمة (أتمتة)

```powershell
# Claude + Cursor فقط
$env:AP_ADAPTERS="claude,cursor"; irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex

# الكل
$env:AP_ADAPTERS="all"; irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex

# AGENTS.md فقط
$env:AP_ADAPTERS="none"; irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex

# تحديث إجباري لملفات البروتوكول
$env:AP_FORCE="1"; $env:AP_ADAPTERS="cursor"; irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

> **لا تستخدم** `| iex -s --` — هذا أسلوب bash وليس PowerShell.

## macOS / Linux / Git Bash / WSL

```bash
# تفاعلي (يسأل عن الـ adapters)
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.sh \
  | bash -s -- --here

# بدون قائمة
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.sh \
  | bash -s -- --here --adapters claude,cursor --non-interactive
```

## ماذا لا يُمس؟

`README.md` · كود التطبيق · `package.json` · `.git/`
