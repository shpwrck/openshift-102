#!/usr/bin/env bash
# Smoke-test the workshop tools image (run after: podman|docker build -f Dockerfile.tools -t TAG .)
set -euo pipefail
img=${1:?usage: verify-tools-image.sh IMAGE:TAG}

podman() { command podman "$@" 2>/dev/null || command docker "$@"; }

podman run --rm --entrypoint bash "$img" -c '
  set -euo pipefail
  echo "== clients =="
  oc version --client | head -n 2
  kubectl version --client=true -o yaml | head -n 5
  helm version --short
  istioctl version --remote=false 2>/dev/null | head -n 6 || istioctl version | head -n 6
  jq --version
  curl --version | head -n 1
  skopeo --version
  crane version
  echo "== docker shim (Helm OCI / registry exercises) =="
  docker manifest inspect alpine:latest | head -n 8
  echo "== done =="
'
