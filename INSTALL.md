# Install & Update — Agent Protocol 1.0.0

**Repo:** https://github.com/MohammedAydan/agent-protocol

---

## Windows (PowerShell) — لا يحتاج Git للأوامر الأساسية

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.ps1 | iex
```

افتح **PowerShell جديد**:

```powershell
agent-protocol version
agent-protocol home

cd D:\path\to\your-project
agent-protocol init --adapters none
agent-protocol update
agent-protocol upgrade
```

| أمر | Git؟ |
|-----|------|
| `version` `home` `help` `init` `update` `upgrade` | لا |
| `doctor` `test` `task` `new` … | اختياري (Git Bash) |

### تثبيت على المشروع فقط (بدون CLI عالمي)

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

---

## macOS / Linux / Git Bash

```bash
# macOS / Linux / Git Bash (on Windows use curl.exe; see docs/WINDOWS.md):
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.sh | bash
export PATH="$HOME/.local/bin:$PATH"

agent-protocol version
agent-protocol init --here --adapters none
agent-protocol update    # يحدث ملفات البروتوكول في المشروع (plans/ تفضل)
agent-protocol upgrade   # يحدث الحزمة العامة من GitHub
```

دليل Windows الكامل: [docs/WINDOWS.md](docs/WINDOWS.md)

---

## الأمان

- لا يستبدل `README.md` ولا كود التطبيق
- `update` لا يحذف `plans/`
- التحميل عبر HTTPS فقط
