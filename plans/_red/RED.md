# RED Evidence — v1.1.0 hardening (pre-fix reproductions)

Branch: `fix/v1.1.0-hardening`. Baseline commit: `aad77e1` (smoke 29/29, stress 33/33).
Environment: PowerShell 5.1.26100.8655, git 2.52.0.windows.1, node v25.9.0,
Git Bash 5.2.37 (D:\AppsAndTools\Git\bin\bash.exe), curl.exe 8.19.0, python absent.

## D1 — T1 numeric specs ambiguous (HAVE RED)

```
$ bash .agents/scripts/task.sh plans/d1 1 start   # T1, 3 acceptance + 3 tasks, no tasks.md
STARTED  - [~] a1  (plans/d1/plan.md)
exit: 0
```

BUG: toggled first Acceptance box `a1`, not first Tasks box `t1`.

## D2 — T3 archive loses epic nesting (HAVE RED)

```
$ bash .agents/scripts/archive.sh plans/pilot/01-sub
archived: plans/pilot/01-sub → plans/_archive/01-sub
exit: 0
$ ls plans/_archive/
01-sub
```

BUG: flat path, parent `pilot/` linkage lost.

## D3 — Windows portability gaps (HAVE RED)

```
$ curl --version        # PowerShell 5.1: curl = Invoke-WebRequest alias
curl : The remote name could not be resolved: '--version'
[...WebCmdletWebResponseException...]
exit: 1 (statement-terminating error)

$ head -1 README.md     # PowerShell 5.1
head : The term 'head' is not recognized as the name of a cmdlet [...]
+ CategoryInfo : ObjectNotFound: (head:String) [], CommandNotFoundException
exit: 1

$ which bash            # PowerShell 5.1
which : The term 'which' is not recognized [...]
+ CategoryInfo : ObjectNotFound: (which:String) [], CommandNotFoundException
exit: 1

$ echo a && echo b      # PowerShell 5.1
+ echo a && echo b; Write-Host "exit:$LASTEXITCODE"
+        ~~
The token '&&' is not a valid statement separator in this version.
+ CategoryInfo : ParserError / InvalidEndOfLine
exit: 1
```

BUG: every POSIX-ism used in v1.0.0 docs fails verbatim in PowerShell 5.1.

## D4 — --help missing (HAVE RED)

```
$ bash .agents/scripts/task.sh --help
Unknown flag: --help
exit: 1
```

## D5 — verify-checklist cannot gate CI (HAVE RED)

```
$ bash .agents/scripts/verify-checklist.sh plans/d1   # plan with open [ ] boxes
exit: 0
```

BUG: always exits 0 even with open boxes.

## D6 — Encoding drift (HAVE RED)

- All 6 framework `plans/*.md` shipped with UTF-8 BOM `EF BB BF`
  (PowerShell `Set-Content -Encoding utf8`); normalized in 0.4.E to no-BOM LF.
- No enforcement exists:

```
$ ls .agents/scripts/lint-encoding.sh
ls: cannot access '.agents/scripts/lint-encoding.sh': No such file or directory
exit: 2
```

- CRLF seed test is a post-fix GREEN gate (lint must fail on planted CRLF/BOM).

## D7 — T1 checkbox semantics (HAVE RED)

```
$ grep -n 'T1 checkbox' AGENTS.md
exit: 1     # no match

$ bash .agents/scripts/new-plan.sh --help
Usage: new-plan.sh [--force] <T0|T1|T2|T3> <name> [parent-epic]
exit: 1     # generic usage, no T1 rule

$ cat .agents/templates/T1-plan.md
# {{NAME}}
**Complexity**: T1
## Goal
## Acceptance
- [ ]
## Tasks
- [ ]
- [ ]
                # no comment line explaining sections
```

## D8 — Dual update path drift (HAVE RED)

Scratch consumers (persisted): `.../ap-red/consumer-bash` (bash CLI init)
vs `.../ap-red/consumer-ps` (PowerShell `agent-protocol init --adapters none`).

```
$ diff -r -x plans consumer-bash consumer-ps
Only in consumer-bash: adapters
exit: 1
```

BUG 1: bash path installs `adapters/` (7 files); PS path installs none.

```
$ diff -r consumer-bash/plans consumer-ps/plans
< # Architecture / ## High-level / TBD ...   (rich bash bootstrap)
> # ARCH.md                                  (PS stub)
... every plans/ file differs ...
exit: 1
```

BUG 2: bootstrap content diverges completely between paths.

```
$ od -An -tx1 consumer-ps/plans/context.md | head -1
 ef bb bf 23 20 50 72 6f 6a 65 63 74 20 43 6f 6e
$ od -An -tx1 consumer-bash/plans/context.md | head -1
 23 20 50 72 6f 6a 65 63 74 20 43 6f 6e 74 65 78
```

BUG 3: PS path writes BOM (`ef bb bf`); bash path writes no-BOM.

## D9 — .gitattributes missing (HAVE RED)

```
$ git clone -q . ap-nogitattr && cd ap-nogitattr
$ git rm -q .gitattributes && git commit -qm test-remove-gitattributes
$ git config core.autocrlf true
$ rm .agents/scripts/task.sh && git checkout -- .agents/scripts/task.sh
$ file .agents/scripts/task.sh
.agents/scripts/task.sh: Bourne-Again shell script, Unicode text, UTF-8 text executable, with CRLF line terminators
exit: 0
```

BUG PROOF: without `.gitattributes`, a Windows `core.autocrlf=true` checkout
corrupts `.sh` files with CRLF.

## D10 — plans/ policy undefined (HAVE RED, pre-policy)

Pre-policy observations (captured before 0.4.C):

```
$ git check-ignore plans/context.md
NOTIGNORED        # exit 1 path: no ignore rule matched

$ git status --short
?? plans/             # 6 untracked bootstrap-residue files, committable via git add -A

$ ls plans/
ARCH.md  DECISIONS.md  PATTERNS.md  SESSION_LOG.md  TECH_STACK.md  context.md
```

BUG: `git add -A` would commit local bootstrap residue into the framework repo.
RESOLVED by D10 Option B (.gitignore committed in `aad77e1`).

## D11 — UTF-8 mojibake in .sh output (HAVE RED)

```
$ grep -n 'warn()\|ok()' .agents/scripts/doctor.sh | head -4
10:warn() { echo "⚠  $1"; ISSUES=$((ISSUES + 1)); }
11:ok()   { echo "✓  $1"; }

$ grep -o '✓\|⚠' .agents/scripts/doctor.sh | head -4 | od -An -tx1
 e2 9a a0 0a e2 9c 93 0a
```

`e2 9a a0` = U+26A0 WARNING SIGN, `e2 9c 93` = U+2713 CHECK MARK.
PowerShell 5.1 console default raster/legacy encoding mis-renders these bytes
as mojibake. No `--ascii` escape hatch exists in v1.0.0.

## D12 — close-plan ignores OVERVIEW.md (HAVE RED)

```
$ bash .agents/scripts/new-plan.sh T3 epicx     # OVERVIEW.md has - [ ] Success box
$ bash .agents/scripts/close-plan.sh plans/epicx
created plans/epicx/review.md
Active Plans updated (removed epicx)
...
exit: 0
```

BUG: closed successfully despite open `[ ]` in OVERVIEW.md (scan covers only
tasks.md + plan.md).

## D13 — promote.sh regression guard (BASELINE, must stay GREEN)

```
$ bash .agents/scripts/promote.sh plans/promo-baseline   # T1 with 3 Tasks
Promoted plans/promo-baseline: T1 → T2
  created: plans/promo-baseline/tasks.md, plans/promo-baseline/context.md
exit: 0
$ cat plans/promo-baseline/tasks.md
# Tasks — promo-baseline

- [ ] task alpha
- [ ] task beta
- [ ] task gamma
```

BASELINE: all 3 tasks survive promote. D1 (section logic) + D7 (template
comment) must not regress this.
