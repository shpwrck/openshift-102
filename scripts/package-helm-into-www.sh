#!/usr/bin/env bash
# Package deploy/helm/openshift-102-workshop into www/helm/ as a static Helm
# chart repository (index.yaml + .tgz). The index uses relative .tgz URLs so
# the same site works for any public base (cluster Route, GitHub Pages, file://).
set -euo pipefail

ROOT_DIR="${1:-.}"
cd "$ROOT_DIR"

if ! command -v helm >/dev/null 2>&1; then
  echo "package-helm-into-www.sh: helm must be in PATH" >&2
  exit 1
fi

mkdir -p www/helm
# shellcheck disable=SC2015,SC2206
shopt -s nullglob
rm -f www/helm/*.tgz
rm -f www/helm/index.yaml

# Prints: chart_version app_version (space-separated) on one line
resolve_chart_versions() {
  if [ -n "${HELM_CHART_VERSION:-}" ]; then
    local app="${HELM_APP_VERSION:-$HELM_CHART_VERSION}"
    echo "${HELM_CHART_VERSION}" "$app"
    return 0
  fi

  # GitHub Pages / similar CI (gh-pages job sets these)
  if [ -n "${GH_REF_TYPE:-}" ] && [ -n "${GH_RUN_NUMBER:-}" ]; then
    if [ "${GH_REF_TYPE}" = "tag" ] && [[ "${GH_REF_NAME:-}" =~ ^v[0-9] ]]; then
      echo "${GH_REF_NAME#v}" "${GH_REF_NAME}"
      return 0
    fi
    local gtag
    gtag=$(git describe --tags --abbrev=0 --match 'v*' HEAD 2>/dev/null || true)
    if [ -n "${gtag}" ]; then
      echo "${gtag#v}+ci.${GH_RUN_NUMBER}" "$(git describe --tags --always 2>/dev/null | head -c80 | tr -d '\n' || echo snapshot)"
      return 0
    fi
    echo "0.0.1+ci.${GH_RUN_NUMBER}" "$(git describe --tags --always 2>/dev/null | head -c80 | tr -d '\n' || echo snapshot)"
    return 0
  fi

  # Local / image build: prefer release tag on HEAD, else <latest>+g<shortsha>
  local vtag
  vtag=$(
    git tag -l --points-at HEAD 2>/dev/null | grep -E '^v[0-9]+(\.[0-9]+)*$' | sort -V | tail -1 || true
  )
  if [ -n "${vtag}" ]; then
    echo "${vtag#v}" "${vtag}"
    return 0
  fi
  local latest
  latest=$(git describe --tags --match 'v*' --abbrev=0 2>/dev/null || true)
  if [ -n "${latest}" ]; then
    local sh
    sh=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
    echo "${latest#v}+g${sh}" "$(git describe --tags --always 2>/dev/null || echo "${latest#v}+g${sh}")"
    return 0
  fi
  local sh
  sh=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
  echo "0.0.0+g${sh}" "0.0.0+g${sh}"
}

read -r CHART_VERSION APP_VERSION <<<"$(resolve_chart_versions)"

echo "Helm static repo: packaging chart version ${CHART_VERSION} (appVersion: ${APP_VERSION})"

helm lint deploy/helm/openshift-102-workshop
helm package deploy/helm/openshift-102-workshop \
  --version "${CHART_VERSION}" \
  --app-version "${APP_VERSION}" \
  -d www/helm
( cd www/helm && helm repo index . )
ls -la www/helm/
