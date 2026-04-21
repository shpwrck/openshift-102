# Disconnected OpenShift install

This bundle is meant for clusters **without outbound internet**. Everything you
need to *run* the workshop is either baked into the container image or shipped
as static files under `www/`.

## What ships in a GitHub release

| Artifact | Purpose |
|----------|---------|
| `openshift-102-offline-<tag>.tar.gz` | Static `www/` tree, Helm chart `.tgz`, this file, and `images-mirror.txt` |
| `openshift-102-workshop-<semver>.tgz` | Helm chart package |
| `openshift-102-<tag>.sbom.cdx.json` | CycloneDX SBOM for the **showroom runtime** image |
| `openshift-102-tools-<tag>.sbom.cdx.json` | CycloneDX SBOM for the **CLI tools** image (`openshift-102-tools`) |
| `ghcr.io/<owner>/openshift-102:<tag>` | Serves the pre-built site (no Antora at runtime) |
| `ghcr.io/<owner>/openshift-102-tools:<tag>` | Shared `oc` / `helm` / `istioctl` / `kubectl`, `skopeo`, and a `docker` CLI shim (see `TOOLS.md`) |

## 1. Mirror images into your registry

On a connected bastion, use `images-mirror.txt` from the offline tarball (or the
release notes list) with `oc image mirror` or `skopeo copy` into your mirror, for
example:

```bash
oc image mirror --keep-manifest-list=true \
  ghcr.io/OWNER/openshift-102:TAG \
  registry.example.com/workshop/openshift-102:TAG
```

Replace `OWNER`, `TAG`, and `registry.example.com/...` with your values. The
runtime image is the only image required to run the Helm chart.

## 2. Install with Helm

```bash
helm upgrade --install openshift-102 ./openshift-102-workshop-HELM_SEMVER.tgz \
  --namespace workshop --create-namespace \
  --set image.repository=registry.example.com/workshop/openshift-102 \
  --set image.tag=TAG
```

Set `route.enabled=false` if you are not on OpenShift or do not want a `Route`.

## 3. Optional: serve static files only

You can copy `www/` to any HTTP file server or OpenShift `ConfigMap` + `emptyDir`
pattern; the Helm chart is the supported path for this repository.

## SBOM

The CycloneDX JSON file describes the **pushed** application image (layers and
dependencies Syft can observe). It is generated at release time in GitHub
Actions, not on the disconnected cluster.
