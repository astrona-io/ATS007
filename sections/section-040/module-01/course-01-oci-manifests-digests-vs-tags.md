# Part 1 — OCI Manifests, Digests vs. Tags

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Signing & Provenance: Cosign and SLSA](./course-02-signing-and-provenance-cosign-and-slsa.md).

## The image is a small object graph, not a file

A container image is not one blob of bytes. Pushing `myapp:1.4.0` to a registry does not upload one artifact — it uploads a small graph of objects, each stored separately and each identified by the `sha256` hash of its own content:

- A **manifest** — a small JSON document listing exactly one config blob and an ordered list of layer blobs, each by digest.
- A **config blob** — the image's runtime metadata: entrypoint, environment, exposed ports, the architecture it targets.
- One or more **layer blobs** — the actual filesystem contents, usually a tarball per layer, stacked in order to form the container's root filesystem.

The **OCI Distribution Spec** is the HTTP API that every conforming registry (Docker Hub, `ghcr.io`, ECR, GCR, a private Harbor instance) implements to serve and accept these objects. Because every object is content-addressed — its digest *is* a hash of its own bytes — two registries holding "the same" manifest digest are provably holding byte-identical content. That property does not hold for names.

`crane` — a small registry client from the `go-containerregistry` project — fetches these objects straight from a registry without pulling or running the image. `crane manifest` retrieves the manifest JSON; `crane config` retrieves the config blob it points at. Both talk to the Distribution API directly, which is why neither needs Docker or a running Pod.

> [!TIP]
> **Try it — look at the object graph directly**
>
> ```sh
> crane manifest docker.io/library/nginx:1.25-alpine | head -20
> ```
>
> Expect something like:
>
> ```text
> {
>   "schemaVersion": 2,
>   "mediaType": "application/vnd.oci.image.manifest.v1+json",
>   "config": {
>     "mediaType": "application/vnd.oci.image.config.v1+json",
>     "size": 8492,
>     "digest": "sha256:1ae23480369f..."
>   },
>   "layers": [
>     {
>       "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
>       "size": 3398000,
>       "digest": "sha256:c6b39de5b33f..."
>     },
> ```
>
> Every `digest` field is a content hash, not a name. The manifest does not say "the config blob" — it says "the blob whose contents hash to exactly this value", which is a claim a registry can either satisfy or fail, but never quietly substitute. Sizes and digests will differ from what is printed here.

## Tags are pointers; digests are identity

A **tag** (`myapp:1.4.0`, `myapp:latest`) is a mutable label a registry stores as a pointer to *whichever* manifest digest was last pushed under that name. Nothing stops someone — a careless CI pipeline re-running a build, or an attacker who has compromised registry push credentials — from pushing a new manifest under an existing tag tomorrow. The tag string in your Pod spec does not change, but what it resolves to can.

A **digest reference** (`myapp@sha256:3f29b8...`) names the manifest itself. There is exactly one manifest with that digest, ever, by construction of how `sha256` works. `myapp@sha256:3f29b8...` today and in a year point at the same bytes, or the reference simply fails to resolve.

This is the root of the classic container supply-chain attack shape often called **tag mutation** or a **time-of-check-to-time-of-use (TOCTOU)** gap: a security team scans and approves `myapp:1.4.0` on Monday, and by Wednesday that same tag has been silently repointed at a different, unscanned image. Every Pod created after Wednesday that references the tag pulls the new bytes, with no record anywhere that the "approved" image and the "running" image are different things.

The cheapest way to feel the difference is to ask the registry what two tags of the same repository resolve to right now.

> [!TIP]
> **Try it — two names, and whether they mean the same thing**
>
> ```sh
> crane digest docker.io/library/nginx:1.25-alpine
> crane digest docker.io/library/nginx:alpine
> ```
>
> Expect something like:
>
> ```text
> sha256:f2802c2a9d09c7db3008b6dcb50b6c48f7ac6b4ce75a1d1e7e0e9e58a7a0d4f1
> sha256:91734281c0ebfc6f1aea979cffeed5079cfe786228a71cc6f1f46a228cde6e34
> ```
>
> Two tag strings, two different manifests. Neither digest is predictable from the tag name, and either tag can be pointed somewhere else tomorrow without the strings changing. The digests you see will differ from these.

The same split shows up inside Kubernetes, where it stops being abstract. A Pod carries the tag in its spec, but the kubelet records the digest it actually resolved that tag to — and those are stored in different fields.

> [!TIP]
> **Try it — see the gap between the tag you wrote and the digest you got**
>
> ```sh
> kubectl -n edge get deployment edge-api -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
> kubectl -n edge get pods -l app=edge-api -o jsonpath='{.items[0].status.containerStatuses[0].image}{"\n"}'
> kubectl -n edge get pods -l app=edge-api -o jsonpath='{.items[0].status.containerStatuses[0].imageID}{"\n"}'
> ```
>
> Expect something like:
>
> ```text
> docker.io/library/nginx:1.25-alpine
> docker.io/library/nginx:1.25-alpine
> docker.io/library/nginx@sha256:3f29b8c1a9e4...
> ```
>
> The digest will not match the one printed here — it is whatever `nginx:1.25-alpine` points at the day you run it, which is exactly the instability this section is about.
>
> The Deployment spec and the Pod's `.status` both still show the tag you wrote — that field is just an echo of the spec. Only `imageID` reports the digest the kubelet actually resolved and pulled at admission time. If the tag were repointed and the Pod recreated, `imageID` is the field that would change; the spec's `image:` string would not.

Those three `jsonpath` queries spell the distinction out field by field, which is what makes them worth running once. In an actual incident nobody types them — `describe` already prints both facts adjacent to each other, labelled `Image:` and `Image ID:`.

> [!TIP]
> **Try it — the same two facts, the way you would actually reach for them**
>
> ```sh
> kubectl -n edge describe pod -l app=edge-api | grep -E '^\s+(Image|Image ID):'
> ```
>
> Expect something like:
>
> ```text
>     Image:          docker.io/library/nginx:1.25-alpine
>     Image ID:       docker.io/library/nginx@sha256:f2802c2a9d09...
> ```
>
> The first line is a request; the second is a receipt. If someone repointed `nginx:1.25-alpine` and this Pod were recreated, the top line would be byte-identical and the bottom line would change — which is exactly why the bottom line is the one worth recording. Your digest will differ.

## Resolving a digest without a running Pod

Both methods above need a Pod that already exists. To learn what a tag points at *before* deploying anything — or to check whether it moved since you last looked — ask the registry directly. That is what the `crane digest` calls earlier in this part were doing: querying the Distribution API for the manifest currently behind a tag, with no cluster involved at all.

That property is what makes `crane digest` usable as evidence. Record the digest a tag resolves to today, run the same command after a suspected repush, and a changed value proves the tag moved — regardless of what any manifest in Git says.

> [!WARNING]
> **Common pitfalls**
>
> - **Trusting the `image:` field in `kubectl describe`/`get`.** It always echoes what you wrote in the spec, tag or digest — it never tells you what actually got pulled. Use `Image ID:` / `imageID` (or `crane digest` against the registry) for that.
> - **Assuming a tag is immutable because it looks like a version.** `1.4.0` carries no more guarantee than `latest`. Semantic-looking tags are repointed by CI pipelines all the time — the convention is social, not enforced by the registry.
> - **Assuming only `:latest` moves.** `latest` is merely the tag people repoint most often. Any tag can be reassigned by anyone with push access to the repository.
> - **Pinning to a digest once and never revisiting it.** A digest pin is only as good as the review that approved it. Rotating to a new, re-reviewed digest on every legitimate release is the point — not freezing forever on one image.

> *A tag answers "what did I ask for"; a digest answers "what did I actually get" — and only the second question is safe to build trust decisions on.*

## Reference

- [OCI Image Format Specification](https://github.com/opencontainers/image-spec) — the manifest/config/layer schema this part summarizes.
- [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec) — the registry HTTP API every registry in this course implements.
- `crane digest --help` — the registry-introspection tool used above.
