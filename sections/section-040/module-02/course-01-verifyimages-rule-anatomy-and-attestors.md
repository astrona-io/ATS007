# Part 1 — verifyImages Rule Anatomy & Attestors

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — mutateDigest & Required Attestations](./course-02-mutatedigest-and-required-attestations.md).

## The fourth rule action

Every Kyverno rule so far in this curriculum has done exactly one of three things: `validate` (accept/reject based on a pattern or condition), `mutate` (rewrite the resource), or `generate` (create a companion resource). `verifyImages` is a fourth, specialized action that runs at Pod admission and answers one question per referenced image: **is there a valid signature from a trusted attestor?**

Unlike a `validate` rule, which only inspects the object already in the admission request, a `verifyImages` rule makes an outbound call: Kyverno's admission controller fetches the signature (and, if configured, attestation) artifacts for the image directly from its registry, using the same OCI-artifact convention Cosign uses to store them. This is why registry reachability from the Kyverno Pod, not just from the node doing the actual image pull, matters operationally.

Before writing any policy, it is worth performing that check by hand. `cosign verify` does precisely what Kyverno will do — resolve the image to a digest, fetch the signature artifact stored beside it, and test it against a public key. Running it yourself separates "is the signature good" from "is my policy YAML right", two failures that look identical once a policy sits in the way.

> [!TIP]
> **Try it — verify the signed image, then the unsigned one**
>
> ```sh
> cosign verify --key /tmp/cosign.pub --allow-insecure-registry \
>   registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0
>
> cosign verify --key /tmp/cosign.pub --allow-insecure-registry \
>   registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0-untrusted
> ```
>
> Expect something like:
>
> ```text
> Verification for registry.../edge-api:1.4.0 --
> The following checks were performed on each of these signatures:
>   - The cosign claims were validated
>   - The signatures were verified against the specified public key
>
> Error: no matching signatures
> ```
>
> Both images contain identical bytes — only the signature differs. The second command fails not because the image is broken but because nothing vouches for it, which is precisely the distinction a `verifyImages` rule is built to act on.

## Anatomy of a verifyImages rule

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-signed-images
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: check-edge-api-signature
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["edge"]
      verifyImages:
        - imageReferences:
            - "registry.registry-system.svc.cluster.local:5000/edge-api:*"
          required: true
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
                      -----END PUBLIC KEY-----
```

- **`imageReferences`** — one or more glob patterns selecting which image reference strings this rule applies to. Only images matching a pattern are checked; everything else in the Pod is ignored by this rule.
- **`attestors`** — the list of trusted signers. `keys.publicKeys` embeds a PEM-encoded public key directly for keyed verification (this course's approach); a keyless setup would use a `keyless` entry naming a trusted OIDC issuer/subject instead. `count: 1` means at least one attestor entry in the list must produce a valid signature.
- **`required: true`** — an image with *no* signature at all, or one signed by a key that isn't in `attestors`, is rejected. Setting `required: false` would let unsigned images through unverified while still flagging signed-but-invalid ones — rarely what you want for enforcement, but useful while a policy is still being validated in a lower environment.

## Wiring in the attestor's public key

The public key never needs to leave the cluster to be usable here — it is pasted directly into the policy as a string, exactly as `cosign public-key` prints it. Because it is a *public* key, embedding it in a ClusterPolicy (a resource any cluster-admin can read) is not a secret-management concern the way embedding the private key would be.

> [!TIP]
> **Try it — confirm the attestor's key matches what signed the image**
>
> ```sh
> kubectl -n edge get configmap cosign-pubkey -o jsonpath='{.data.cosign\.pub}'
> ```
>
> Expect something like:
>
> ```text
> -----BEGIN PUBLIC KEY-----
> MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
> -----END PUBLIC KEY-----
> ```
>
> This is the exact public key the lab's bootstrap generated and used to sign the sample image. Paste it verbatim into your policy's `attestors[].entries[].keys.publicKeys` field — a single mismatched character means every signature check fails.

## Watching the rule decide

Once the policy is applied, the decision moves out of your terminal and into the admission path — and the feedback changes shape entirely. A refused Pod does not start and then fail into `CrashLoopBackOff`; it is never created at all, and whoever submitted it gets the rejection synchronously, from the API server, with the policy and rule named in the error. That immediacy is the whole point of enforcing at admission rather than detecting afterwards.

> [!TIP]
> **Try it — attempt the unsigned image with your policy active**
>
> ```sh
> kubectl -n edge run untrusted-check \
>   --image=registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0-untrusted \
>   --restart=Never
> ```
>
> Expect something like:
>
> ```text
> Error from server: admission webhook "mutate.kyverno.svc-fail" denied the request:
> resource Pod/edge/untrusted-check was blocked due to the following policies
>
> require-signed-edge-images:
>   check-edge-api-signature: 'failed to verify image .../edge-api:1.4.0-untrusted:
>     .. no matching signatures'
> ```
>
> The Pod was never persisted, so there is nothing to clean up. Note that the rejection reason is the same `no matching signatures` that `cosign verify` reported by hand earlier — the engine is identical, only the moment of asking has moved. To take the guard back off, `kubectl delete clusterpolicy require-signed-edge-images`.

> [!WARNING]
> **Common pitfalls**
>
> - **Scoping `imageReferences` too broadly.** A pattern like `"*"` verifies every image in every matched Pod, including the Kyverno-managed system images and anything else already running unsigned — a good way to lock yourself out of your own cluster. Scope tightly to the images you actually control and have signed.
> - **Forgetting `required: true`.** Without it, an attacker (or a careless deploy) can simply omit a signature entirely and sail through unverified, since the rule only judges signatures that *are* present. It reads like a safety setting and behaves like an exemption.
> - **Forgetting that verification needs the registry, every time.** Every matching Pod admission is a live registry round-trip from the Kyverno Pod. With `Enforce`, an unreachable registry or an expired credential blocks every matching deployment cluster-wide — including during an incident, when you most need to ship.
> - **Treating "signed" as "trustworthy".** A signature proves a key vouched for a digest. If that key is unmanaged — shared, long-lived, or sitting in a developer's home directory — the signature proves very little. Key custody is part of the control, not a detail beneath it.

> *A `verifyImages` rule doesn't inspect the Pod spec — it reaches out to the registry and asks the registry to prove who signed what it's about to serve.*

## Reference

- [Kyverno documentation — Verify Images](https://kyverno.io/docs/writing-policies/verify-images/) — the full `verifyImages` schema this part summarizes.
- `cosign public-key --key cosign.key` — prints the PEM public key from a keyed keypair, in the exact format `attestors[].entries[].keys.publicKeys` expects.
