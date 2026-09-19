# Install

**Repo:** https://github.com/MohammedAydan/agent-protocol

## Windows — أقصر أمر

PowerShell داخل مجلد مشروعك:

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

Harness محدد:

```powershell
$env:AP_ADAPTERS="claude,cursor"; irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

أو تحميل ثم تشغيل:

```powershell
iwr -useb https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 -OutFile ap.ps1
powershell -ExecutionPolicy Bypass -File .\ap.ps1
```

## macOS / Linux / Git Bash / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.sh | bash -s -- --here --adapters all --non-interactive
```

## ملاحظات

- **لا يستبدل** `README.md` ولا كود التطبيق.
- على Windows الأوامر الكاملة للشُل تحتاج [Git for Windows](https://git-scm.com/download/win)؛ التثبيت نفسه يعمل بـ PowerShell فقط.
- الفرع الافتراضي: `main` (حتى تنشئ tag `v1.0.0`).
