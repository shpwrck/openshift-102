# Workshop CLI tools image

The image built from `Dockerfile.tools` (published as `ghcr.io/<owner>/openshift-102-tools:<tag>`)
gives every learner the same CLIs **without** installing `oc`, Helm, or other tools on a laptop—and
**without** requiring a local `oc` binary at all.

## Deploy from the OpenShift web console (recommended)

1. In the console, open your **Project**.
2. Click **+** → **Import YAML**.
3. Paste the contents of `**openshift-102-tools-deployment.yaml`** (from this repo under `deploy/`,
  or from the root of the offline release tarball), edit the `image:` line if you use a mirror or a
   specific tag, then **Create**.
4. Go to **Workloads → Deployments → openshift-102-workshop-tools** → **Pods** → your pod → **Terminal**.
  If the terminal starts `sh`, run `**bash`** or `**bash -l**` for an interactive bash session; the
   image’s `~/.bashrc` prints a short reminder of installed tools.

The Deployment keeps one replica running; the image entrypoint sleeps until you delete the workload.

## Helm chart baked into the tools image

At build time, `**Dockerfile.tools**` copies `deploy/helm/openshift-102-workshop` into the image. Inside the pod:

- Path: `**~/chart**` (symlink) or `**/usr/local/share/openshift-102/helm/openshift-102-workshop**`
- The chart is the **same commit** as the image build (not auto-updated after the image is built).
- The **showroom** HTTP site includes a pre-built static Helm **repository** at `**/helm/`** (same package as the chart above); use the Route host with `helm repo add` if you prefer a chart repo to a file path in the tools pod.

Example (from a Terminal on the tools pod, after `oc login` / in-cluster credentials work):

```bash
helm upgrade --install my-showroom ~/chart -n my-namespace --create-namespace \
  --set image.repository=ghcr.io/OWNER/openshift-102 \
  --set image.tag=vX.Y.Z \
  --set tools.enabled=false
```

Use `**--set tools.enabled=false**` when you are installing **from** the tools pod so the chart does not create a second tools `Deployment`. If you install the chart **elsewhere** (laptop CI, another pod) and want the bundled tools pod too, leave the default `**tools.enabled: true`** in `values.yaml`.

If you install the showroom with **Helm** from a normal workstation, the chart can still create the tools workload for you (`tools.enabled`, default **true**) so you do not need a separate paste-only manifest.

## Included tools


| Tool                                          | Workshops                                                      |
| --------------------------------------------- | -------------------------------------------------------------- |
| `oc`, `kubectl`                               | Deploy, Istio, Prometheus (OpenShift flows)                    |
| `helm`                                        | Helm workshop                                                  |
| `istioctl`                                    | Istio workshop (version matches Istio **1.23.x** lab text)     |
| `curl`, `wget`, `jq`, `git`, `gpg` (`gnupg2`) | Prometheus, Helm signing exercises, general scripting          |
| `skopeo`                                      | Registry copy / inspection; raw manifest for the `docker` shim |


## `docker` compatibility (Helm OCI lab)

There is **no Docker Engine** in the image. `/usr/local/bin/docker` is a small shim that maps:

- `docker manifest inspect` → `skopeo inspect --raw`
- `docker pull` → `skopeo copy` to a temporary `dir:` layout (prints the path)
- `docker image inspect` → `skopeo inspect`
- `docker history` → `skopeo inspect … \| jq` (layer metadata)

For anything beyond that, use `skopeo` or `podman` on a host with a real engine.

## Optional: one-off pod with `oc` on your workstation

If you already have `oc` installed locally:

```bash
oc run workshop-tools -it --rm --restart=Never \
  --image=ghcr.io/OWNER/openshift-102-tools:vX.Y.Z \
  --command -- bash
```

Replace `OWNER` and tag with your mirrored image coordinates in disconnected environments.