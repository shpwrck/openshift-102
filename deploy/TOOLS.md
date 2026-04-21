# Workshop CLI tools image

The image built from `Dockerfile.tools` (published as `ghcr.io/<owner>/openshift-102-tools:<tag>`)
is meant for **per-user terminals** (for example `oc run ... --rm -it --image=... bash`) so every
learner has the same CLIs without installing them on a laptop.

## Included tools

| Tool | Workshops |
|------|------------|
| `oc`, `kubectl` | Deploy, Istio, Prometheus (OpenShift flows) |
| `helm` | Helm workshop |
| `istioctl` | Istio workshop (version matches Istio **1.23.x** lab text) |
| `curl`, `jq`, `git`, `gpg` (`gnupg2`) | Prometheus, Helm signing exercises, general scripting |
| `skopeo` | Registry copy / inspection; raw manifest for the `docker` shim |

## `docker` compatibility (Helm OCI lab)

There is **no Docker Engine** in the image. `/usr/local/bin/docker` is a small shim that maps:

* `docker manifest inspect` → `skopeo inspect --raw`
* `docker pull` → `skopeo copy` to a temporary `dir:` layout (prints the path)
* `docker image inspect` → `skopeo inspect`
* `docker history` → `skopeo inspect … \| jq` (layer metadata)

For anything beyond that, use `skopeo` or `podman` on a host with a real engine.

## Example pod on OpenShift

```bash
oc run workshop-tools -it --rm --restart=Never \
  --image=ghcr.io/OWNER/openshift-102-tools:vX.Y.Z \
  --command -- bash
```

Replace `OWNER` and tag with your mirrored image coordinates in disconnected environments.
