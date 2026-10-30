#!/usr/bin/env bash
# Structural + arithmetic eval for anti-ai-slop-ui (1.0).
#
# Pins the contract (SKILL.md), the catalog (T01-T23 with weights), the shared schema
# (owned by ux-review), and the slop arithmetic: it recomputes ids, slop_score, band, tiers,
# priority scores, and summary for tests/fixtures/example-slop.json.
#
# Usage: bash tests/eval.sh   (PYTHON=/path/to/python for an interpreter with jsonschema)
# Exit 0 on pass, 1 on any failure. SKIP is not a pass.
set -u
cd "$(dirname "$0")/.."
PY=${PYTHON:-python3}
SCHEMA=../ux-review/references/findings-schema.json
PASS=0; FAIL=0; SKIP=0
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
skip() { echo "SKIP  $1"; SKIP=$((SKIP+1)); }
chk() { grep -qF -- "$2" "${3:-SKILL.md}" && pass "$1" || fail "$1 (missing: $2)"; }

echo "== Frontmatter =="
head -1 SKILL.md | grep -qx -- '---' && pass "frontmatter opens" || fail "frontmatter opens"
fm=$(awk 'NR==1{next} /^---$/{exit} {print}' SKILL.md)
grep -qx 'name: anti-ai-slop-ui' <<<"$fm" && pass "name matches dir" || fail "name matches dir"
grep -qx 'user-invocable: true' <<<"$fm" && pass "user-invocable" || fail "user-invocable"
grep -qE '^  owner: ' <<<"$fm" && pass "metadata.owner" || fail "metadata.owner"
dlen=$(awk '/^description:/{f=1;next} f&&/^[a-z-]+:/{exit} f{printf "%s ", $0}' <<<"$fm" | wc -c)
[ "$dlen" -gt 100 ] && [ "$dlen" -le 1024 ] && pass "description $dlen chars (<=1024)" || fail "description $dlen chars"
grep -qi 'use when' <<<"$fm" && pass "description has triggers" || fail "description has triggers"
n=$(wc -l < SKILL.md); [ "$n" -le 250 ] && pass "SKILL.md $n lines (<=250)" || fail "SKILL.md $n lines (>250)"

echo "== Contract =="
chk "signs, not proof" '**signs, not proof.**'
chk "shared schema by path" '../ux-review/references/findings-schema.json'
chk "deterministic pre-pass is optional" 'Neither tool is required.'
chk "copy is delegated" 'Never rewrite copy here'
chk "fabrication is P0" 'No source: P0'
chk "craft credit keeps an auditable finding" '`severity: 0`, `tell_weight: 0`'
chk "per-tell cap" 'contributes its weight **once**'
chk "score formula" 'slop_score = round(100 x sum(weights of tells found) / sum(weights of applicable tells))'
chk "bands" '0 `none`, 1-2 `isolated`, 3-6 `pattern`, 7+ `template-grade`'
chk "weights labelled uncalibrated" 'starting point'
chk "over-correction warning" '**Over-correction warning.**'
chk "stable id recipe" 'sha1("anti-ai-slop-ui|<rule>|<screen>|<locator>")'
chk "Gotchas section" '## Gotchas'
chk "weights labelled in catalog" 'Weights are a starting point, calibrate.' references/tells.md
[ -f "$SCHEMA" ] && pass "shared schema present at $SCHEMA" || fail "shared schema missing at $SCHEMA"

echo "== Catalog =="
c=0; for i in $(seq -w 1 23); do grep -qE "^\| T$i \|" references/tells.md && c=$((c+1)) || echo "  missing T$i"; done
[ "$c" -eq 23 ] && pass "T01-T23 in tells.md" || fail "tells.md has $c/23"
for s in 'Han Kim / IOV Labs' 'Gesso Build, Inc.' 'Hallmark contributors' 'Feranmi' 'Miqdad Badjuber' 'Apache-2.0' 'cited, not copied'; do chk "attribution: $s" "$s" references/tells.md; done

echo "== Schema and worked example =="
SCHEMA="$SCHEMA" "$PY" - <<'PYEOF'
import json, hashlib, os, re, sys
ok = True; skipped = False
def res(c, m):
    global ok
    print(("PASS  " if c else "FAIL  ") + m); ok = ok and c
schema = json.load(open(os.environ["SCHEMA"])); ex = json.load(open("tests/fixtures/example-slop.json"))
try:
    import jsonschema
    jsonschema.Draft202012Validator.check_schema(schema)
    errs = list(jsonschema.Draft202012Validator(schema).iter_errors(ex))
    res(not errs, "example validates against the shared schema" + ("" if not errs else ": " + errs[0].message))
except ImportError:
    print("SKIP  jsonschema not installed"); skipped = True
W = {}; proof = set()
for line in open("references/tells.md"):
    m = re.match(r"\| (T\d\d) \|(?:[^|]*\|){3} ([^|]+) \|", line)
    if m:
        wt = m.group(2).strip()
        if wt == "P0": proof.add(m.group(1))
        else: W[m.group(1)] = int(wt)
res(sum(W.values()) == 99 and proof == {"T14", "T15", "T16", "T21"}, f"style weights sum {sum(W.values())}, proof tells {sorted(proof)}")
sc = ex["scores"]; F = ex["findings"]; live = [f for f in F if f["diff"] != "resolved"]
res(all(sc[k] is None for k in ("laws", "heuristics", "wcag", "platform", "overall_pct", "grade")), "ux-review sections are null")
res(len({f["id"] for f in F}) == len(F), "finding ids are unique")
for f in F:
    loc = f["location"]["selector"] or f["location"]["region"]
    res(f["id"] == "slop_" + hashlib.sha1(f"anti-ai-slop-ui|{f['rule']}|{f['location']['screen']}|{loc}".encode()).hexdigest()[:10], f"{f['rule']}: id recomputes")
    res(abs(f["priority_score"] - round(f["severity"] ** 2 * f["reach"] * f["confidence"] / f["effort"], 2)) < 1e-9, f"{f['rule']}: priority_score recomputes")
    if f["craft_credit"]: res(f["severity"] == 0 and f["tell_weight"] == 0, f"{f['rule']}: craft credit zeroes severity and weight")
    elif f["rule"] in W: res(f["tell_weight"] == W[f["rule"]], f"{f['rule']}: tell_weight matches catalog")
found = {f["rule"] for f in live if f["rule"] in W and not f["craft_credit"]}
app = [t for t in W if t not in sc["na_reasons"]]
slop = round(100 * sum(W[t] for t in found) / sum(W[t] for t in app))
res(slop == sc["slop_score"], f"slop_score recomputes {slop}")
n = len(found); band = "none" if n == 0 else "isolated" if n <= 2 else "pattern" if n <= 6 else "template-grade"
res(band == sc["slop_band"], f"band recomputes {band} ({n} tells)")
wc = re.compile(r"^\d\.\d+\.\d+$")
for f in live:
    if f["rule"] in proof: want = "P0"
    elif any(wc.match(a) for a in f["also"]): want = "P1"
    elif band == "template-grade" and not f["craft_credit"]: want = "P2"
    else: want = "P3"
    res(f["tier"] == want, f"{f['rule']}: tier {f['tier']} (expected {want})")
s = ex["summary"]
res(all(s[t.lower()] == sum(f["tier"] == t for f in live) for t in ("P0", "P1", "P2", "P3")), "summary tier counts")
key = [(f["diff"] == "resolved", f["tier"], -f["priority_score"], f["id"]) for f in F]
res(key == sorted(key), "findings in canonical order")
sys.exit(1 if not ok else 3 if skipped else 0)
PYEOF
r=$?; case $r in 0) pass "example arithmetic block";; 3) pass "example arithmetic block"; skip "schema validation (no jsonschema)";; *) fail "example arithmetic block";; esac

echo "== Public-repo hygiene =="
SCAN="SKILL.md references tests"
hits=$(grep -rnE '/(U[s]ers|h[o]me|V[o]lumes)/[A-Za-z0-9_-]+|\.claude/pro[j]ects/-|/works[p]ace/' $SCAN)
[ -z "$hits" ] && pass "no private path shapes" || { echo "$hits"; fail "private path shape present"; }
# Same private-name contract as ux-review: the list is never committed.
tf=${UX_PRIVATE_TERMS:-tests/private-terms.local}
if [ ! -s "$tf" ]; then
  if [ -n "${UX_PRIVATE_TERMS:-}" ]; then fail "UX_PRIVATE_TERMS set but $tf missing or empty"; else skip "private-name scan: no $tf (result is NOT a clean bill)"; fi
else
  found=0
  while IFS= read -r t; do t=${t%%#*}; t=$(echo "$t" | xargs); [ -z "$t" ] && continue
    h=$(grep -rliF --exclude="$(basename "$tf")" -- "$t" $SCAN); [ -n "$h" ] && { echo "  private name (masked) in: $h"; found=1; }
  done < "$tf"
  [ $found = 0 ] && pass "no private names ($(grep -cvE '^\s*(#|$)' "$tf") terms)" || fail "private name present"
fi

echo; echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
[ "$FAIL" -eq 0 ]
