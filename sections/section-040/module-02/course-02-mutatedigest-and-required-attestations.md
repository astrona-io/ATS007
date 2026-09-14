# Part 2 — mutateDigest & Required Attestations

> Prerequisite: [Part 1 — verifyImages Rule Anatomy & Attestors](./course-01-verifyimages-rule-anatomy-and-attestors.md). Next: [Section 040 Capstone](../capstone/labs/lab-01/question.md).

## Closing the tag-mutation gap with mutateDigest

Module 1 established the core supply-chain problem: a tag can be repointed after you approved it, so admitting a Pod because its *tag* had a valid signature at admission time does not guarantee the *bytes the kubelet later pulls* are the same ones that were checked. A `verifyImages` rule closes this gap with one field:

```yaml
      verifyImages:
        - imageReferences:
            - "registry.registry-system.svc.cluster.local:5000/edge-api:*"
          mutateDigest: true
          required: true
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      ...
                      -----END PUBLIC KEY-----
```

With `mutateDigest: true`, once Kyverno verifies the signature against the digest the tag resolves to *right now*, it rewrites the Pod's image field in place — before the object is ever persisted to etcd — from `edge-api:1.4.0` to `edge-api@sha256:<the exact digest that was verified>`. The kubelet never sees the tag at all; it pulls the digest Kyverno already checked. Even if the tag is repointed a second later, this Pod's spec is now permanently anchored to the bytes that passed verification.

> [!TIP]
> **Try it — watch the rewrite happen**
>
> ```sh
> kubectl -n edge run signed-check --image=registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0 --restart=Never
> kubectl -n edge get pod signed-check -o jsonpath='{.spec.containers[0].image}{"\n"}'
> ```
>
> Expect something like:
>
> ```text
> pod/signed-check created
> registry.registry-system.svc.cluster.local:5000/edge-api@sha256:3f29b8c1a9e4...
> ```
>
> You submitted a tag reference; the object Kubernetes actually stored already carries the digest. This is the mutation happening at admission time, not after the fact.

It is worth confirming that the digest Kyverno wrote is not some value it invented, but exactly what the registry serves for that tag right now. This is the same `crane digest` question from Module 1, asked of the same tag the policy just processed — the two answers should be identical.

> [!TIP]
> **Try it — confirm the rewritten digest is the one the registry actually serves**
>
> ```sh
> crane digest --insecure registry.registry-system.svc.cluster.local:5000/edge-api:1.4.0
> kubectl -n edge get pod signed-check -o jsonpath='{.spec.containers[0].image}{"\n"}'
> ```
>
> Expect something like:
>
> ```text
> sha256:3f29b8c1a9e4...
> registry.registry-system.svc.cluster.local:5000/edge-api@sha256:3f29b8c1a9e4...
> ```
>
> The same digest on both lines, arrived at independently — one by asking the registry directly, one by reading what Kyverno persisted. That equality is the guarantee `mutateDigest` buys: the stored spec names the exact bytes that passed verification. Your digest will differ from the one shown.
>
> Clean up with `kubectl -n edge delete pod signed-check` when you are done.

## Requiring more than a signature: attestations

A bare signature (Part 1) proves identity: *this key vouched for this digest*. An `attestations` block goes further, requiring a signed in-toto/SLSA-style predicate to also be present and to satisfy conditions you write:

```yaml
      verifyImages:
        - imageReferences:
            - "registry.registry-system.svc.cluster.local:5000/edge-api:*"
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: "{{ /* same public key as Part 1 */ }}"
          attestations:
            - predicateType: https://slsa.dev/provenance/v1
              conditions:
                - all:
                    - key: "{{ builder.id }}"
                      operator: Equals
                      value: "https://ci.internal/approved-pipeline"
```

Here the rule requires not just *a* valid signature, but a signed provenance predicate whose `builder.id` field matches your approved CI system exactly. An image signed by the right key but built on someone's laptop — never having gone through the approved pipeline — has a valid signature and still fails this rule, because the required attestation predicate is either missing or doesn't satisfy the condition. This is the mechanism that turns "who signed it" into "what process was it required to survive."

> [!WARNING]
> **Common pitfalls**
>
> - **Treating attestations as optional polish.** Without an `attestations` block, `verifyImages` only ever answers "who signed this" — it cannot detect a correctly-signed image that skipped your build pipeline entirely (e.g., someone with signing-key access hand-crafting and signing an image locally).
> - **Enforcing cluster-wide before staging in Audit.** Because verification happens on the live registry at every matching Pod's admission, a misconfigured attestor (wrong key, unreachable registry) with `validationFailureAction: Enforce` blocks *every* matching deployment cluster-wide the moment it's applied. Prove the policy correct with `validationFailureAction: Audit` and review the resulting `PolicyReport` entries first.

> *`mutateDigest` proves the Pod that runs is the Pod that was checked; an `attestations` requirement proves the image that was checked came from a process you actually trust.*

## Reference

- [Kyverno documentation — Verify Images: mutateDigest](https://kyverno.io/docs/writing-policies/verify-images/) — the digest-rewrite behavior this part demonstrates.
- [Kyverno documentation — Verify Images: Attestations](https://kyverno.io/docs/writing-policies/verify-images/#attestations) — the full `attestations`/`conditions` schema.
- [SLSA Provenance predicate](https://slsa.dev/provenance/v1) — the predicate type referenced in the example above.
