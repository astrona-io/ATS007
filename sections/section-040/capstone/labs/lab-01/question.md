# Question

Solve this question on: `cluster`

A Deployment named `legacy-worker` is running in the `edge` namespace, referencing its image by a mutable tag. Find the digest it actually pulled and re-point the Deployment to that digest.

An in-cluster registry at `registry.registry-system.svc.cluster.local:5000` holds two images in the `edge-api` repository: `edge-api:1.4.0` (signed with a Cosign keypair generated for this lab; the public key is in the `edge` namespace as ConfigMap `cosign-pubkey`, key `cosign.pub`) and `edge-api:1.4.0-untrusted` (never signed).

Write a `ClusterPolicy` named `require-signed-edge-images` that requires a valid signature from the public key in `cosign-pubkey` for every image matching `registry.registry-system.svc.cluster.local:5000/edge-api:*` in the `edge` namespace, rewriting admitted images to their verified digest. Prove that a Pod built from the untrusted image is rejected, and that a Pod built from the signed image is admitted with its reference rewritten to a digest.
