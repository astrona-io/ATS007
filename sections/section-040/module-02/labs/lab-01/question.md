# Question

Solve this question on: `cluster`

Kyverno is already installed. An in-cluster registry at `registry.registry-system.svc.cluster.local:5000` holds two images in the `edge-api` repository:
*   `edge-api:1.4.0` — signed with a Cosign keypair generated for this lab. The public key is available in the `edge` namespace as ConfigMap `cosign-pubkey`, key `cosign.pub`.
*   `edge-api:1.4.0-untrusted` — an identical image, never signed.

1.  Write a `ClusterPolicy` named `require-signed-edge-images` with a `verifyImages` rule that:
    *   Matches Pods in the `edge` namespace.
    *   Applies to images matching `registry.registry-system.svc.cluster.local:5000/edge-api:*`.
    *   Requires a valid signature from the public key in `cosign-pubkey` (`required: true`).
    *   Sets `mutateDigest: true`.
    *   Uses `validationFailureAction: Enforce`.
2.  Confirm a Pod created from `edge-api:1.4.0-untrusted` is **rejected** by the admission controller.
3.  Confirm a Pod created from `edge-api:1.4.0` is **admitted**, and that its stored image reference has been rewritten to a `@sha256:...` digest.
