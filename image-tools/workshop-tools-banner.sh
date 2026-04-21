# Sourced from ~/.bashrc for interactive shells (e.g. oc exec -it … bash).
# shellcheck shell=bash
[[ $- == *i* ]] || return 0
[[ -n ${_OS102_TOOLS_BANNER_DONE-} ]] && return 0
export _OS102_TOOLS_BANNER_DONE=1

printf '\n'
printf '%s\n' "OpenShift 102 workshop CLI image — tools on PATH:"
printf '%s\n' "  oc  kubectl  helm  istioctl  jq  curl  wget  git  gpg  skopeo"
printf '%s\n' "  docker  →  client shim only (no engine): manifest inspect | pull | image inspect | history"
printf '%s\n' "Bundled showroom Helm chart: ~/chart → helm upgrade --install RELEASE ~/chart -n NS --set image.repository=… --set image.tag=…"
printf '%s\n' "  (installing *from* this pod: add --set tools.enabled=false to skip a second tools Deployment)"
printf '\n'
