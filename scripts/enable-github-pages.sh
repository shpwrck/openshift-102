#!/usr/bin/env bash
# Enable GitHub Pages with "GitHub Actions" as the build source (workflow).
# Requires: gh CLI (https://cli.github.com/) and a logged-in account with
# admin (or "manage GitHub Pages settings") on the repository.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/enable-github-pages.sh [--dry-run]

Without --dry-run: calls the GitHub REST API to create or update the Pages
site so builds use your Actions workflow (see .github/workflows/gh-pages.yml).

Manual alternative (same outcome):
  Repository on GitHub → Settings → Pages → Build and deployment → Source:
  select "GitHub Actions".

If this script fails with 404 on POST, ensure you have admin access on the repo.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

if ! command -v gh >/dev/null 2>&1; then
  printf 'Install the GitHub CLI (gh), then re-run.\n' >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  repo_url="https://github.com/OWNER/REPO/settings/pages"
  if remote=$(git remote get-url origin 2>/dev/null); then
    case "$remote" in
      git@github.com:*.git)
        path=${remote#git@github.com:}
        path=${path%.git}
        repo_url="https://github.com/${path}/settings/pages"
        ;;
      https://github.com/*.git)
        path=${remote#https://github.com/}
        path=${path%.git}
        repo_url="https://github.com/${path}/settings/pages"
        ;;
    esac
  fi
  printf 'Not logged into GitHub. Run:\n  gh auth login\n\nOr open:\n  %s\n  and set Source to "GitHub Actions".\n' "$repo_url" >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

remote=$(git remote get-url origin)
OWNER=""
REPO=""
case "$remote" in
  git@github.com:*.git)
    path=${remote#git@github.com:}
    path=${path%.git}
    OWNER=${path%%/*}
    REPO=${path#*/}
    ;;
  https://github.com/*.git)
    path=${remote#https://github.com/}
    path=${path%.git}
    OWNER=${path%%/*}
    REPO=${path#*/}
    ;;
  *)
    printf 'Unsupported remote URL: %s\n' "$remote" >&2
    exit 1
    ;;
esac

default_branch=main
if sym=$(git symbolic-ref -q refs/remotes/origin/HEAD); then
  default_branch=${sym#refs/remotes/origin/}
fi

api_base="repos/${OWNER}/${REPO}/pages"
post_put() {
  local method=$1
  gh api -X "$method" "$api_base" \
    -f build_type=workflow \
    -F "source[branch]=${default_branch}" \
    -F "source[path]=/"
}

if gh api "$api_base" >/dev/null 2>&1; then
  printf 'Pages site already exists; switching build to GitHub Actions (workflow).\n'
  if [[ "$DRY_RUN" == true ]]; then
    printf 'Dry-run: would PUT %s with build_type=workflow\n' "$api_base"
    exit 0
  fi
  post_put PUT
  printf 'Updated %s/%s Pages to workflow builds.\n' "$OWNER" "$REPO"
else
  printf 'Creating Pages site for %s/%s (workflow builds).\n' "$OWNER" "$REPO"
  if [[ "$DRY_RUN" == true ]]; then
    printf 'Dry-run: would POST %s\n' "$api_base"
    exit 0
  fi
  post_put POST
  printf 'Enabled Pages on %s/%s. Trigger a deploy from the Actions tab if needed.\n' "$OWNER" "$REPO"
fi

printf 'Site settings: https://github.com/%s/%s/settings/pages\n' "$OWNER" "$REPO"
