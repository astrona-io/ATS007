# Summary

An image is a graph of content-addressed pieces. A digest names the exact bytes, and a tag only points at them today.

## What you learned

An OCI image is a manifest that lists a config blob and layer blobs, each by digest. The manifest has its own digest, which identifies the whole image. A tag is a movable pointer, and a digest never moves. `crane digest` asks a registry what a tag points at, and a Pod's `imageID` shows what the node pulled.

Cosign stores a signature as another artifact in the registry, next to the image. A signature covers the manifest digest, so it covers every layer. An attestation is a signed statement about how an image was built or checked, for example a SLSA provenance record.

The key facts to remember are these:

- Pin production to a digest, not a tag.
- A signature proves who vouched for the bytes, not that they are safe.
- An attestation adds facts such as the build process.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Digest Pinning Lab](./labs/lab-01/README.md) | OCI Manifests, Digests vs. Tags | Pin a Deployment to the digest its Pod pulled |

## Check yourself

<details>
<summary>1. Why can a tag change but a digest cannot?</summary>

A digest is computed from the content. A tag is only a name that a publisher can move.
</details>

<details>
<summary>2. Where do you find the digest a Pod pulled?</summary>

In the Pod's `status.containerStatuses[].imageID`.
</details>

<details>
<summary>3. What does a signature cover?</summary>

The manifest digest, and through it the config and every layer.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-040-module-01-playground
astrona destroy ats-007-lab-011
```

> *A tag is a nickname. A digest is a fingerprint.*

<!-- astrona:playground:destroy -->
