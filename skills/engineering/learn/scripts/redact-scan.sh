#!/usr/bin/env bash
# learn — blocking secret/PII scan. Run on every memory file before triage AND on
# the staged diff before any commit (`git diff --cached | redact-scan.sh -`).
# Usage: redact-scan.sh <file|->...   Exit 1 if anything matches (values are masked).
# Allowlist: example.com/.org/.net emails, noreply/users.noreply.github.com, 555-01xx phones.
set -u
P_TOKEN='(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
P_ASSIGN='(api[_-]?key|secret|token|passw(or)?d|client[_-]?secret|bearer)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9_./+=-]{8,}'
P_URLCRED='[a-z]+://[^/[:space:]:@]+:[^/[:space:]@]+@'
P_EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
P_PHONE='(\+?[0-9]{1,3}[ .-]?)?\(?[0-9]{3}\)?[ .-][0-9]{3}[ .-][0-9]{4}'
hits=0
scan() { # $1 label, $2 name
  local n=0
  while IFS= read -r line; do
    n=$((n+1)); kind=""
    if   grep -qE "$P_TOKEN"   <<<"$line"; then kind=token
    elif grep -qiE "$P_ASSIGN" <<<"$line"; then kind=key-assignment
    elif grep -qE "$P_URLCRED" <<<"$line"; then kind=url-credentials
    elif e=$(grep -oE "$P_EMAIL" <<<"$line" | grep -viE '@(example\.(com|org|net)|users\.noreply\.github\.com)$|^noreply@'); [ -n "$e" ]; then kind=email
    elif p=$(grep -oE "$P_PHONE" <<<"$line" | grep -vE '555[ .-]01[0-9]{2}'); [ -n "$p" ]; then kind=phone
    fi
    if [ -n "$kind" ]; then
      echo "BLOCK $kind $2:$n: $(sed -E 's/[A-Za-z0-9]{4,}/****/g; s/[0-9]/#/g' <<<"$line" | cut -c1-80)"
      hits=$((hits+1))
    fi
  done
}
for f in "$@"; do
  if [ "$f" = - ]; then scan stdin stdin; else scan file "$f" < "$f"; fi
done
[ $hits -eq 0 ] && { echo "CLEAN"; exit 0; }
echo "BLOCKED: $hits finding(s). Remove or rotate; never commit. Nothing else proceeds."; exit 1
