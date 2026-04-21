#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

missing=0
for path in \
  workshops/helm-workshop/content/modules \
  workshops/deploy-workshop/content/modules \
  workshops/istio-workshop/content/modules \
  workshops/prometheus-workshop/content/modules \
  workshops/helm-workshop/content/lib \
  workshops/helm-workshop/content/supplemental-ui
do
  if [[ ! -e "$path" ]]; then
    printf 'Missing expected path: %s\n' "$path" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  cat >&2 <<'EOF'
Initialize Git submodules, then re-run this script:

  git submodule update --init --recursive

If you cloned without submodules:

  git submodule update --init --recursive
EOF
  exit 1
fi
