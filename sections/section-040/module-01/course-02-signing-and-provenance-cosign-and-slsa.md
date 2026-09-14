# Part 2 — Signing & Provenance: Cosign and SLSA

> Prerequisite: [Part 1 — OCI Manifests, Digests vs. Tags](./course-01-oci-manifests-digests-vs-tags.md). Next: [Module 2 — Verifying Images with Kyverno verifyImages](../module-02/course.md).

A digest tells you that the bytes you are about to run are *exactly* the bytes someone pushed. It tells you nothing about *who* pushed them or *how* they were produced. Signing answers the first question; attestations answer the second.

## Cosign: signatures as another OCI artifact

**Cosign**, part of the Sigstore project, is the tool this curriculum uses to sign and verify container images. Its central design decision is that a signature is not stored in some separate signature-tracking service — it is pushed to the *same registry*, next to the image, as another OCI artifact. Anywhere the image can be pulled from, the signature can be pulled from too, with no extra infrastructure.

### Where the signature actually lives

The mechanism behind that is worth knowing, because it explains how a verifier finds a signature it was never told the location of. Cosign derives the signature's location from the image's own digest, by convention: an image whose manifest digest is `sha256:3f29b8…` has its signature stored in the *same repository* under the tag `sha256-3f29b8….sig` — the digest with its colon swapped for a dash, plus a `.sig` suffix.

Nothing needs to be registered or indexed. A verifier holding the image reference resolves it to a digest, rewrites that digest into the tag form, and pulls that tag. If the object is there, there is a signature to check; if the registry returns a 404, the image is unsigned. This is why `cosign verify` and Kyverno's `verifyImages` both need nothing but registry access, and why signatures survive an image being copied between registries only if the `.sig` tag is copied too — a common cause of "it verified in staging and not in production".

> As an analogy: it is like filing a document's signature page in the same drawer, under a label computed from the document's own contents. Anyone who has the document can work out the label. The analogy breaks down in that the computed label here is cryptographically bound to the contents — alter the document and the label you compute no longer points anywhere.

Signing works one of two ways:

- **Keyed signing** — you generate a standard public/private keypair (`cosign generate-key-pair`), sign with the private key, and distribute the public key to every verifier. This is fully offline-capable: no external service has to be reachable to sign or to verify, which is why this course uses it.
- **Keyless signing** — instead of a long-lived keypair, Cosign requests a short-lived certificate from Sigstore's public **Fulcio** certificate authority, bound to an OIDC identity (a GitHub Actions workflow, a Google account), and records the signing event in the public **Rekor** transparency log. Nothing to store or rotate, but it depends on reaching Sigstore's public infrastructure at both sign and verify time.

Either way, what a valid signature proves is narrow and specific: **this exact digest was signed by the holder of this specific key (or this specific verified identity)**. It says nothing about what process produced the image, what it contains, or whether it's safe to run — only who vouched for it.

Note the shape of that claim. It proves *identity*, not *quality*: a signature says "this key signed this digest", not "this image is free of vulnerabilities" and not "this image came out of the approved build pipeline". Somebody with access to the signing key can sign an image built on their laptop, and it verifies perfectly.

What a signature covers is worth being precise about, because it is broader than it first appears. Cosign signs the *manifest* digest — and because the manifest lists the config blob and every layer blob by their own digests (Part 1), signing that one value transitively commits to the entire object graph. Change a single byte in any layer and that layer's digest changes, which changes the manifest, which changes the manifest digest, which invalidates the signature.

> [!TIP]
> **Try it — the config blob a signature transitively covers**
>
> ```sh
> crane config docker.io/library/nginx:1.25-alpine | head -15
> ```
>
> Expect something like:
>
> ```text
> {
>   "architecture": "amd64",
>   "config": {
>     "Env": [
>       "PATH=/usr/local/sbin:/usr/local/bin:...",
>       "NGINX_VERSION=1.25.3"
>     ],
>     "Entrypoint": ["/docker-entrypoint.sh"],
> ...
> ```
>
> This is a separate object from the manifest, fetched by its own digest. Nobody signs it directly — yet it cannot be swapped without breaking the manifest's signature, because the manifest names it by content hash. Field values and ordering will differ from what is printed here.

This playground has `crane` but no signing stack, so there is no signature here to inspect — `nginx:1.25-alpine` is a public image nobody signed with a key you hold. Module 2's playground adds `cosign`, a local registry, and a signed image, and that is where signing and verification become hands-on.

## Attestations: proving what happened, not just who signed

An **attestation** is a signed statement about an image that goes beyond "I vouch for this" — it's a structured, signed predicate describing a fact about how the image came to exist. Common predicate types follow the **in-toto** attestation format, and the **SLSA** (Supply-chain Levels for Software Artifacts) framework standardizes what a trustworthy build-provenance predicate should contain: which source repository and commit produced the image, which build system ran, and whether the build process was isolated from tampering.

In practice an attestation lets you ask sharper questions than a bare signature can answer: not just "did our release pipeline sign this," but "did this image pass its vulnerability scan," "was it built from `main` at this exact commit," or "did it go through the approved CI pipeline at all, as opposed to someone's laptop." Kyverno's `verifyImages` rule type (Module 2) can require and evaluate these predicates directly, using JMESPath conditions against the attestation payload — turning "who signed this" into "what process was this image required to go through before it could run."

> [!WARNING]
> **Common pitfalls**
>
> - **Treating "signed" as "safe."** A valid signature only proves identity and integrity of the bytes at the moment of signing — it says nothing about vulnerabilities or malicious content unless paired with an attestation that specifically asserts a scan result.
> - **Losing the private signing key.** With keyed signing there is no recovery path for a lost private key other than re-signing every image with a newly generated pair and redistributing the new public key to every verifier — plan key custody accordingly.

> *A signature proves who vouched for these exact bytes; an attestation proves what process those bytes were required to survive before being signed.*

## Reference

- [Sigstore / Cosign documentation](https://docs.sigstore.dev/) — keyed and keyless signing flows referenced above.
- [in-toto attestation framework](https://in-toto.io/) — the attestation predicate format Kyverno evaluates.
- [SLSA framework](https://slsa.dev/) — the build-provenance levels referenced above.
