# Disconnected OpenShift install

This bundle is meant for clusters **without outbound internet**. Everything you
need to *run* the workshop is either baked into the container image or shipped
as static files under `www/`.

## What ships in a GitHub release


| Artifact                                    | Purpose                                                                                                                                                                                                                                |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `openshift-102-offline-<tag>.tar.gz`        | Static `www/` tree, Helm chart `.tgz`, this file, `TOOLS.md`, `openshift-102-tools-deployment.yaml`, and `images-mirror.txt`                                                                                                           |
| `openshift-102-workshop-<semver>.tgz`       | Helm chart package                                                                                                                                                                                                                     |
| `openshift-102-<tag>.sbom.cdx.json`         | CycloneDX SBOM for the **showroom runtime** image                                                                                                                                                                                      |
| `openshift-102-tools-<tag>.sbom.cdx.json`   | CycloneDX SBOM for the **CLI tools** image (`openshift-102-tools`)                                                                                                                                                                     |
| `ghcr.io/<owner>/openshift-102:<tag>`       | Serves the pre-built site (no Antora at runtime). The same `www/` tree is baked in, including a **Helm chart repository** at the `/helm/` path (in-cluster: `https://<your-route>/helm/`) with `index.yaml` and a `.tgz` of the chart. |
| `ghcr.io/<owner>/openshift-102-tools:<tag>` | Shared `oc` / `helm` / `istioctl` / `kubectl`, `skopeo`, and a `docker` CLI shim (see `TOOLS.md`)                                                                                                                                      |


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
Helm chart pulls the **showroom** image and, by default, the **CLI tools** image
(`tools.enabled: true`). Mirror both if you use the bundled tools pod.

## 2. Install with Helm

### 2a. In-showroom Helm chart repository (optional)

The static site in the **runtime** image and in `www/` (offline bundle) includes
`www/helm/` (URL path: `/helm/`). After you deploy, use your OpenShift `Route`
or load balancer host as the base, then point Helm at the repository root:

```bash
helm repo add openshift-102-workshop "https://<route-or-host>/helm/"
helm repo update
helm show values openshift-102-workshop/openshift-102-workshop
helm upgrade --install my-showroom openshift-102-workshop/openshift-102-workshop \
  -n workshop --create-namespace \
  --set image.repository=registry.example.com/workshop/openshift-102 --set image.tag=TAG
```

`index.yaml` uses relative chart URLs so the same `www/helm` tree is valid
whether you use GitHub Pages, an in-cluster `Route`, or a mirrored host.

### 2b. From a downloaded chart package (`.tgz` from this release)

```bash
helm upgrade --install openshift-102 ./openshift-102-workshop-HELM_SEMVER.tgz \
  --namespace workshop --create-namespace \
  --set image.repository=registry.example.com/workshop/openshift-102 \
  --set image.tag=TAG \
  --set tools.image.repository=registry.example.com/workshop/openshift-102-tools \
  --set tools.image.tag=TAG
```

Set `route.enabled=false` if you are not on OpenShift or do not want a `Route`.
Set `tools.enabled=false` if you do not want the CLI tools `Deployment` in the release namespace.

## 3. Optional: serve static files only

You can copy `www/` to any HTTP file server or OpenShift `ConfigMap` + `emptyDir`
pattern; the Helm chart is the supported path for this repository. The copy
includes `www/helm/` (see section 2a) if you used the same build as a release
or a local `antora` + `scripts/package-helm-into-www.sh` run.

## SBOM

The CycloneDX JSON file describes the **pushed** application image (layers and
dependencies Syft can observe). It is generated at release time in GitHub
Actions, not on the disconnected cluster.