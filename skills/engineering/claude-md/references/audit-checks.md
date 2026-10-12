# Audit-mode checks (detail for phases A-2 through A-5.5)

## Phase A-2: secret patterns

- `(?i)(secret|token|api[_-]?key|password)\s*[:=]\s*['"]\S{8,}['"]`
- `(?i)auth[_-]?secret\s*[:=]\s*\S{8,}` — e.g. a pasted `AUTH_SECRET`
- Base64-ish JWT prefixes: `eyJ[A-Za-z0-9_-]{10,}`
- URLs with embedded credentials: `https?://[^:/\s]+:[^@\s]+@`
- Stripe/OpenAI/Anthropic key prefixes: `sk_live_`, `sk_test_`, `pk_live_`, `sk-ant-`, `sk-proj-`
- Supabase/Neon connection strings: `postgres(ql)?://[^:]+:[^@]+@`

**If any match:** mark file 🔴 P0 LEAK. Report the line, pattern matched, required
remediation: rotate the secret in source system, edit CLAUDE.md to reference env var
names only, scrub git history (`git filter-repo --path CLAUDE.md --invert-paths` or BFG).

## Phase A-3: drift categories

For each claim CLAUDE.md makes, verify against real code:

1. **MCP servers** — diff against `settings.json` / `.mcp.json` / `mcp.json`
2. **API routes** — grep for routes named in CLAUDE.md; verify each exists in `src/app/api/` or routes file
3. **Cron jobs** — count asserted vs actual `*/cron*` files / `vercel.json` crons / `wrangler.toml` triggers
4. **Env vars** — every env var named should appear in `.env.example` or be read by code (`process.env.<NAME>` / `os.environ["<NAME>"]`)
5. **External services** — flag contradictions (claims one vendor's SMTP but code imports that vendor's REST client)
6. **Directory structure** — diff enumerated dirs against `ls` output

For each drift finding: report the CLAUDE.md line, the actual code fact, and the one-line
edit that fixes it.

## Phase A-4: duplicate + structure checks

1. Detect duplicate section headings (`^## `, `^### ` appearing ≥2 times)
2. Detect near-duplicate paragraphs (same first 60 characters on two different lines)
3. Report any line contradicting another line in the same file

## Phase A-5: instruction count + prescriptive ratio

1. Count instructions — any line starting with an imperative verb (Always, Never, Use, Don't, Prefer, Avoid, Run, Check, Write, Edit, Follow) OR inside a bullet list under a "Rules/Conventions/Do/Don't" heading
2. Instruction-count bands — a different metric from the R1 line budget, so report both:
   - ≤ 100 instructions: 🟢 healthy
   - 100–200: 🟡 monitor
   - \> 200: 🟠 over — suggest splits or cuts
3. Descriptive vs prescriptive classifier:
   - **Descriptive** = describes what code already shows ("this is a Next.js app with Postgres")
   - **Prescriptive** = tells Claude what to do ("when editing migrations, add both up and down")

   Report the ratio. Descriptive lines are budget waste.

## Phase A-5.5: hook-candidate detection

CLAUDE.md instructions are advisory — community evidence puts compliance around 70–80%.
Rules phrased as absolute commands fail this ceiling silently. Scan for
deterministic-sounding rules and flag them for hook conversion.

Patterns to flag:

- Lines starting with `NEVER`, `Never`, `Always`, `MUST`, `Do not` followed by a verb
- Rules naming destructive commands: `rm -rf`, `git push --force`, `git reset --hard`, `DROP TABLE`, `truncate`, a production deploy flag, `gcloud ... delete`
- Rules requiring 100% pre-commit gates: lint, typecheck, test must pass before commit

For each match: report the line, classify as `hook-candidate`, and identify the right hook type:

- Destructive command gates → `PreToolUse` hook returning exit code 2 to block
- Pre-commit verification → `PreToolUse` on git commit or `PostToolUse` on file Edit/Write
- Always-run-after-edit checks → `PostToolUse` hook

Report wording: "This rule reads as deterministic but lives in advisory territory.
Convert to a hook in `.claude/settings.json` for 100% enforcement; keep the CLAUDE.md
line as documentation of the hook's intent, or remove it." Cite
[Anthropic hooks docs](https://code.claude.com/docs/en/hooks) and the ~80% advisory ceiling.
