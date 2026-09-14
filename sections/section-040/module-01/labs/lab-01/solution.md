# Solution Walkthrough

Follow these steps against the cluster to resolve and pin the image digest:

---

## Step 1: Inspect the Deployment's Image Reference

```sh
kubectl -n edge get deployment edge-api -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```
You will see a tag-based reference, e.g. `docker.io/library/nginx:1.25-alpine`.

---

## Step 2: Resolve the Real Digest

Check what the running Pod actually pulled:
```sh
kubectl -n edge get pods -l app=edge-api -o jsonpath='{.items[0].status.containerStatuses[0].imageID}{"\n"}'
```
Or query the registry directly without needing a running Pod:
```sh
crane digest docker.io/library/nginx:1.25-alpine
```
Both should report the same digest, e.g. `sha256:3f29b8c1a9e4...`. `imageID` is the authoritative record of what the kubelet actually pulled; `crane digest` proves what the tag resolves to right now.

---

## Step 3: Pin the Deployment to the Digest

Edit the Deployment so the image field uses the digest instead of the tag:
```sh
kubectl -n edge set image deployment/edge-api \
  edge-api=docker.io/library/nginx@sha256:3f29b8c1a9e4...
```
(Replace the digest with the one you resolved in Step 2 — it will differ by build.)

---

## Step 4: Verify the Rollout

```sh
kubectl -n edge rollout status deployment/edge-api --timeout=120s
kubectl -n edge get deployment edge-api -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```
The Deployment's image field now shows the `@sha256:...` form, and the rollout reports success — the same content is running, but the reference can no longer be silently repointed by a future tag push.

Once verified, run the local validation suite to pass the lab!
