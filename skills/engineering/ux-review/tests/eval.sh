#!/usr/bin/env bash
# Structural + arithmetic eval for ux-review (1.0), including the slop and motion passes.
#
# The skill's runtime output is model-written, so this eval pins two things a model cannot
# be trusted to hold by itself: the design contract in SKILL.md and references/, and the
# scoring arithmetic, by recomputing every derived number in the worked example (ids,
# priority scores, tiers, item scores, section %, overall %, grade caps, slop score and band,
# summary, order).
# If the example and the rules ever disagree, one of them is wrong and this fails.
#
# Usage: bash tests/eval.sh   (PYTHON=/path/to/python to pick an interpreter with jsonschema)
# Exit 0 on pass, 1 on any failure. A skipped check prints SKIP and is not a pass.
set -u
cd "$(dirname "$0")/.."
PY=${PYTHON:-python3}
PASS=0; FAIL=0; SKIP=0
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
skip() { echo "SKIP  $1"; SKIP=$((SKIP+1)); }
chk() { grep -qF -- "$2" "${3:-SKILL.md}" && pass "$1" || fail "$1 (missing: $2)"; }

echo "== Frontmatter =="
head -1 SKILL.md | grep -qx -- '---' && pass "frontmatter opens" || fail "frontmatter opens"
fm=$(awk 'NR==1{next} /^---$/{exit} {print}' SKILL.md)
grep -qx 'name: ux-review' <<<"$fm" && pass "name matches dir" || fail "name matches dir"
grep -qx 'user-invocable: true' <<<"$fm" && pass "user-invocable" || fail "user-invocable"
grep -qE '^  owner: ' <<<"$fm" && pass "metadata.owner" || fail "metadata.owner"
dlen=$(awk '/^description:/{f=1;next} f&&/^[a-z-]+:/{exit} f{printf "%s ", $0}' <<<"$fm" | wc -c)
[ "$dlen" -gt 100 ] && [ "$dlen" -le 1024 ] && pass "description $dlen chars (<=1024)" || fail "description $dlen chars"
grep -qi 'use when' <<<"$fm" && pass "description has triggers" || fail "description has triggers"
for t in 'does this look' 'AI-generated' 'de-slop' 'anti-slop review' 'motion review' 'micro-interactions'; do grep -qF -- "$t" <<<"$fm" && pass "trigger: $t" || fail "trigger: $t"; done
n=$(wc -l < SKILL.md); [ "$n" -le 250 ] && pass "SKILL.md $n lines (<=250)" || fail "SKILL.md $n lines (>250)"

echo "== Contract in SKILL.md =="
chk "item score formula" '4 - max(severity of live findings linked'
chk "per-screen rollup: min for P0/P1" 'is the **min** across screens if any linked live finding is P0 or P1'
chk "per-screen rollup: mean otherwise" 'otherwise the **mean**'
chk "default section weights" 'laws 35, heuristics 25, wcag 25, platform 15'
chk "weights overridable" '--weights'
chk "grade caps" 'any live P0 caps the grade at D'
chk "priority formula" 'severity^2 x reach x confidence / effort'
chk "WCAG => P1" 'any WCAG 2.2 AA failure'
chk "copy is delegated, not rewritten" 'Never rewrite copy here'
chk "loop location is a caller choice, default PR previews" 'default is on PR previews'
chk "regression rules" '**Regression: block the merge'
chk "plateau rule" '**Plateau:**'
chk "stuck rule" '**Stuck:**'
chk "stable id recipe" 'sha1("ux-review|<rule>|<screen>|<element_key>")'
chk "raw selector is never hashed" 'It is never hashed'
for m in '`source checked, none found`: you checked' '`source not checked`: a missing' '`source found`: the source exists'; do chk "unsourced-claim guard marker: ${m%%:*}" "$m"; done
chk "signs, not proof" 'Tells are **signs, not proof**'
chk "slop: per-tell cap" 'contributes its weight **once**'
chk "slop: score formula" 'slop_score = round(100 x sum(weights of tells found) / sum(weights of applicable tells))'
chk "slop: bands" '0 `none`, 1-2 `isolated`, 3-6 `pattern`, 7+ `template-grade`'
chk "slop: band only, no gate" 'gate nothing on the score except the loop'"'"'s regression rule'
chk "slop: regression rule" '`slop_score` rising 10 or more'
chk "slop: craft credit before tiering" 'Run craft credit before tiering'
chk "slop: token tell key" 'key `token|<token name>`'
chk "1.3.5 autocomplete is a WCAG item" '| 1.3.5 | Identify input purpose' references/platform-targets.md
chk "motion: not a scored section" 'not as a new scored section'
chk "motion: weights unchanged" 'Weights stay 35/25/25/15'
chk "motion: not observable" 'not observable'
chk "motion: never fabricate" 'Never fabricate a motion finding'
chk "motion: 2.3.3 report-only" '2.3.3 note (AAA, report-only, no cap)'
chk "motion: 2.3.1 seizure" '2.3.1 (Level A, P0)'
chk "Gotchas section" '## Gotchas'
for r in laws.md heuristics.md platform-targets.md slop-tells.md motion.md findings-schema.json example-page.json sources.md; do
  grep -qF "references/$r" SKILL.md && [ -f "references/$r" ] && pass "reference $r linked and present" || fail "reference $r"
done

echo "== Catalog completeness =="
LAWS="aesthetic-usability-effect choice-overload chunking cognitive-bias cognitive-load doherty-threshold fittss-law flow goal-gradient-effect hicks-law jakobs-law law-of-common-region law-of-proximity law-of-pragnanz law-of-similarity law-of-uniform-connectedness mental-model millers-law occams-razor paradox-of-the-active-user pareto-principle parkinsons-law peak-end-rule postels-law selective-attention serial-position-effect teslers-law von-restorff-effect working-memory zeigarnik-effect"
c=0; for l in $LAWS; do grep -qE "^\| $l \|" references/laws.md && c=$((c+1)) || echo "  missing law: $l"; done
[ "$c" -eq 30 ] && pass "all 30 law ids in laws.md" || fail "laws.md has $c/30 law ids"
c=0; for i in 1 2 3 4 5 6 7 8 9 10; do grep -qE "^\| H$i \|" references/heuristics.md && c=$((c+1)); done
[ "$c" -eq 10 ] && pass "H1-H10 in heuristics.md" || fail "heuristics.md has $c/10"
for s in Apache-2.0 MIT 'Next Level Builder'; do chk "sources.md credits: $s" "$s" references/sources.md; done
c=0; for i in $(seq -w 1 23); do grep -qE "^\| T$i \|" references/slop-tells.md && c=$((c+1)) || echo "  missing T$i"; done
[ "$c" -eq 23 ] && pass "T01-T23 in slop-tells.md" || fail "slop-tells.md has $c/23"
chk "slop weights labelled uncalibrated" 'Weights are a starting point, calibrate.' references/slop-tells.md
for s in 'Han Kim / IOV Labs' 'Gesso Build, Inc.' 'Hallmark contributors' 'Feranmi' 'Miqdad Badjuber' 'cited, not copied'; do chk "slop attribution: $s" "$s" references/slop-tells.md; done
c=0; for i in 01 02 03 05 06 07 08 09 $(seq 15 26); do grep -qE "^### M$i " references/motion.md && c=$((c+1)) || echo "  missing M$i"; done
[ "$c" -eq 20 ] && pass "20 active checks (M01-M26 minus lens ids) in motion.md" || fail "motion.md has $c/20 active checks"
c=0; for i in 04 10 11 12 13 14; do grep -qE "^### M$i " references/motion.md && echo "  lens id M$i is still a check"; grep -qE "^\| M$i \|" references/motion.md && c=$((c+1)); done
[ "$c" -eq 6 ] && ! grep -qE "^### M(04|10|1[1-4]) " references/motion.md && pass "M04, M10, M11-M14 are lens rows, not checks" || fail "lens ids ($c/6 rows)"
n=$(grep -c '^\*\*Source:\*\*' references/motion.md); [ "$n" -eq 20 ] && pass "every active check has a Source line" || fail "Source lines: $n/20"
for l in '**research**' '**standard**' '**platform**' '**practitioner**' '**house heuristic**'; do chk "motion: strength label $l" "$l" references/motion.md; done
! grep -qi 'reel heuristic' references/motion.md && pass "motion: no reel-sourced thresholds" || fail "motion: reel heuristic still present"
chk "motion: lens not scored" 'Animation principles lens (not scored' references/motion.md
chk "motion: M01 paint exemption" 'Exempt when the result paints within 400 ms' references/motion.md
chk "motion: M09 floor" 'An exit of 200 ms or less is never a finding' references/motion.md
chk "motion: M08 100-150 band" 'so 100-150 ms is fine' references/motion.md
chk "loop: scored-item change is a baseline reset" 'or the set of scored items changed'
chk "motion: M02 repeat guard" '**Repeat guard:**' references/motion.md
chk "motion: pixels blocked on production" 'block ad and analytics requests' references/motion.md
chk "motion: read after settle" '**MX2 Read after settle.**' references/motion.md
chk "motion: easing from keyframes" 'effect.getKeyframes()' references/motion.md
chk "motion: Astryx credited (MIT)" 'Copyright (c) 2026 Meta Platforms, Inc.' references/motion.md
chk "2.2.2 is a scored WCAG item" '| 2.2.2 | Pause, stop, hide' references/platform-targets.md
chk "2.3.1 is a scored WCAG item" '| 2.3.1 | Three flashes' references/platform-targets.md
chk "Doherty: Nielsen limits cited" 'about 0.1 s feels instant, 1 s keeps the flow of thought, 10 s holds attention' references/laws.md
chk "Doherty: 400 ms is a house heuristic" '**House heuristic:** visible feedback within about 400 ms' references/laws.md
chk "motion: prefers-reduced-motion" 'prefers-reduced-motion' references/motion.md
chk "motion: 2.3.3 AAA report-only" 'Level AAA: report-only, no grade cap' references/motion.md
chk "motion: 2.3.1 Level A" '2.3.1' references/motion.md
chk "motion: Apple HIG cited" 'developer.apple.com/design/human-interface-guidelines/motion' references/motion.md
chk "motion: Material easing cited" 'm3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration' references/motion.md
chk "motion: WCAG 2.3.3 understanding cited" 'WAI/WCAG22/Understanding/animation-from-interactions' references/motion.md
chk "motion: Fitts/Hick/Doherty not duplicated" 'already in [laws.md](laws.md)' references/motion.md
chk "sources.md points at motion credits" 'motion.md' references/sources.md

echo "== Schema and worked example =="
LAWS="$LAWS" "$PY" - <<'PYEOF'
import json, hashlib, os, re, sys, unicodedata
from urllib.parse import urlsplit
def norm_screen(s):
    if not s.startswith("/") and "://" not in s: return re.sub(r"\s+", "-", s.strip().lower())
    u = urlsplit(s); p = (u.fragment if u.fragment.startswith("/") else u.path).lower().rstrip("/") or "/"
    return "/".join(":id" if re.fullmatch(r"\d+|[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}", g) else g for g in p.split("/"))
def norm_key(role, name=""):
    n = re.sub(r"\s+", " ", unicodedata.normalize("NFKC", name).lower()).strip()
    n = re.sub(r"\d+", "#", n)[:60]
    return f"{role.lower()}|{n}" if n else role.lower()
ok = True; skipped = False; bad = 0
def res(cond, msg):
    global ok
    print(("PASS  " if cond else "FAIL  ") + msg); ok = ok and cond
schema = json.load(open("references/findings-schema.json"))
ex = json.load(open("references/example-page.json"))
try:
    import jsonschema
    jsonschema.Draft202012Validator.check_schema(schema); res(True, "findings-schema.json is valid JSON Schema 2020-12")
    errs = list(jsonschema.Draft202012Validator(schema).iter_errors(ex))
    res(not errs, "example validates against schema" + ("" if not errs else ": " + errs[0].message))
except ImportError:
    print("SKIP  jsonschema not installed: schema checked as JSON only (set PYTHON= to an interpreter with jsonschema)")
    skipped = True
laws = os.environ["LAWS"].split(); H = [f"H{i}" for i in range(1, 11)]
W = {}; proof = set()
for line in open("references/slop-tells.md"):
    m = re.match(r"\| (T\d\d) \|(?:[^|]*\|){3} ([^|]+) \|", line)
    if m: (proof.add(m.group(1)) if m.group(2).strip() == "P0" else W.__setitem__(m.group(1), int(m.group(2))))
res(sum(W.values()) == 99 and proof == {"T14", "T15", "T16", "T21"}, f"slop style weights sum {sum(W.values())}, proof tells {sorted(proof)}")
sc = ex["scores"]
res(sorted(sc["laws"]) == sorted(laws), "example scores all 30 laws")
res(sorted(sc["heuristics"]) == sorted(H), "example scores H1-H10")
plat = open("references/platform-targets.md").read()
res(all(f"| {k} |" in plat for k in list(sc["wcag"]) + list(sc["platform"])), "every example wcag/platform key is defined in platform-targets.md")
res(all(k in sc["na_reasons"] for sec in ("laws", "heuristics", "wcag", "platform") for k, v in sc[sec].items() if v == "n/a"), "every n/a has a reason")
res(norm_screen("https://x.example/Signup/?a=1#f") == "/signup" and norm_screen("/e/42/edit/") == "/e/:id/edit" and norm_screen("/") == "/" and norm_screen("Home Screen") == "home-screen" and norm_screen("https://x.example/#/Settings") == "/settings", "screen normalization")
res(norm_key("button", "  Create\n  ACCOUNT ") == "button|create account" and norm_key("img") == "img" and norm_key("heading", "1,204 signups") == "heading|#,# signups", "element_key normalization")
F = ex["findings"]; live = [f for f in F if f["diff"] != "resolved"]
res(len({f["id"] for f in F}) == len(F), "finding ids are unique")
for f in F:
    L = f["location"]; k = L.get("element_key", "")
    res(L["screen"] == norm_screen(L["screen"]) and (k.startswith("region:") or k == norm_key(*k.split("|", 1))), f"{f['id']}: screen and element_key are normalized")
    want = "uxr_" + hashlib.sha1(f"ux-review|{f['rule']}|{L['screen']}|{k}".encode()).hexdigest()[:10]
    res(f["id"] == want, f"{f['id']}: id recomputes from skill|rule|screen|element_key")
    ev = f["evidence"]; mk = [m for m in ("source checked, none found", "source not checked", "source found") if m in ev]
    if f["rule"] in ("T14", "T15", "T16") or re.search(r"unsourced|fabricat", ev, re.I):
        res(len(mk) == 1 and {"source checked, none found": True, "source not checked": f["tier"] != "P0" and f["severity"] <= 3 and f["confidence"] <= 0.5, "source found": f["severity"] == 1}.get(mk[0], False), f"{f['id']}: claim guard: one marker {mk} and its cap")
    if f["rule"] in W:
        res(f["tell_weight"] == (0 if f["craft_credit"] else W[f["rule"]]) and (not f["craft_credit"] or f["severity"] == 0), f"{f['id']}: tell_weight matches catalog, craft credit zeroes it")
        res(f["severity"] == (0 if f["craft_credit"] else 2 if sc["slop_band"] == "template-grade" else 1), f"{f['id']}: style tell severity follows band and craft credit")
    if f["rule"] in proof: res(f.get("tell_weight") is None, f"{f['id']}: proof tell carries no weight")
    res(abs(f["priority_score"] - round(f["severity"] ** 2 * f["reach"] * f["confidence"] / f["effort"], 2)) < 1e-9, f"{f['id']}: priority_score recomputes")
    base = {4: "P0", 3: "P1", 2: "P2"}.get(f["severity"], "P3")
    wc = any(x in sc["wcag"] for x in [f["rule"]] + f["also"])
    res(f["tier"] <= base and (not wc or f["tier"] <= "P1"), f"{f['id']}: tier {f['tier']} respects severity and WCAG>=P1")
    res(f["tier"] == base or bool(f.get("tier_reason")), f"{f['id']}: tier override names a tier_reason")
for sec in ("laws", "heuristics", "wcag", "platform"):
    for item, v in sc[sec].items():
        if v == "n/a": continue
        sev = [f["severity"] for f in live if f["rule"] == item or item in f["also"]]
        if (max(0, 4 - max(sev)) if sev else 4) != v: res(False, f"{sec}.{item}={v} does not match linked findings"); bad += 1
if not bad: res(True, "every item score = 4 - max(linked live severity)")
pct = {}
for sec in ("laws", "heuristics", "wcag", "platform"):
    a = [v for v in sc[sec].values() if v != "n/a"]
    pct[sec] = round(sum(a) / (4 * len(a)) * 100, 1) if a else None
res(pct == sc["sections_pct"], f"sections_pct recomputes {pct}")
w = ex["config"]["section_weights"]; use = [k for k in pct if pct[k] is not None]
ov = round(sum(pct[k] * w[k] for k in use) / sum(w[k] for k in use), 1)
res(ov == sc["overall_pct"], f"overall_pct recomputes {ov}")
g = "A" if ov >= 90 else "B" if ov >= 80 else "C" if ov >= 70 else "D" if ov >= 60 else "F"; cap = None
if any(f["tier"] == "P0" for f in live) and g < "D": g, cap = "D", "P0"
if any(x in sc["wcag"] for f in live for x in [f["rule"]] + f["also"]) and g < "C": g, cap = "C", "WCAG"
res(g == sc["grade"] and (cap is None) == (sc["grade_cap_reason"] is None), f"grade {g} with cap {cap}")
s = ex["summary"]
res(all(s[t.lower()] == sum(f["tier"] == t for f in live) for t in ("P0", "P1", "P2", "P3")), "summary tier counts match live findings")
res(all(s[d] == sum(f["diff"] == d for f in F) for d in ("new", "persisting", "resolved", "regressed")), "summary diff counts match")
key = [(f["diff"] == "resolved", f["tier"], -f["priority_score"], f["id"]) for f in F]
res(key == sorted(key), "findings in canonical order (live first, tier, score desc, id)")
found = {t for f in live if not f.get("craft_credit") for t in [f["rule"]] + f["also"] if t in W}
app = [t for t in W if t not in sc["na_reasons"]]
slop = round(100 * sum(W[t] for t in found) / sum(W[t] for t in app)) if app else None
res(slop == sc["slop_score"], f"slop_score recomputes {slop}")
n = len(found); band = None if slop is None else "none" if n == 0 else "isolated" if n <= 2 else "pattern" if n <= 6 else "template-grade"
res(band == sc["slop_band"], f"slop_band recomputes {band} ({n} tells)")
sys.exit(1 if not ok else 3 if skipped else 0)
PYEOF
r=$?; case $r in 0) pass "example arithmetic block";; 3) pass "example arithmetic block"; skip "schema validation (no jsonschema)";; *) fail "example arithmetic block";; esac

echo "== Public-repo hygiene =="
SCAN="SKILL.md references tests"
hits=$(grep -rnE '/(U[s]ers|h[o]me|V[o]lumes)/[A-Za-z0-9_-]+|\.claude/pro[j]ects/-|/works[p]ace/' $SCAN)
[ -z "$hits" ] && pass "no private path shapes" || { echo "$hits"; fail "private path shape present"; }
# The private-name list is never committed (a published denylist is itself the leak).
# Terms: $UX_PRIVATE_TERMS, else tests/private-terms.local (gitignored). One per line.
tf=${UX_PRIVATE_TERMS:-tests/private-terms.local}
if [ ! -s "$tf" ]; then
  if [ -n "${UX_PRIVATE_TERMS:-}" ]; then fail "UX_PRIVATE_TERMS set but $tf missing or empty"; else skip "private-name scan: no $tf (result is NOT a clean bill)"; fi
else
  found=0
  while IFS= read -r t; do t=${t%%#*}; t=$(echo "$t" | xargs); [ -z "$t" ] && continue
    h=$(grep -rliF --exclude="$(basename "$tf")" -- "$t" $SCAN); [ -n "$h" ] && { echo "  private name (masked) in: $h"; found=1; }
  done < "$tf"
  [ $found = 0 ] && pass "no private names (term list: $(grep -cvE '^\s*(#|$)' "$tf") terms)" || fail "private name present"
fi

echo; echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
[ "$FAIL" -eq 0 ]
