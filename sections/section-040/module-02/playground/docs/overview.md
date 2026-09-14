# Overview: PLAYGROUND — Verifying Images with Kyverno verifyImages (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A **kind Kubernetes cluster** (context `kind-section-040-module-02-playground`),
  with `kubectl` already pointed at it. There is no SSH step and no VM.
- **Kyverno v1.13.2** in the `kyverno` namespace, patched with
  `--allowInsecureRegistry` so its admission controller can fetch signatures
  from the plain-HTTP registry below. (A real cluster would use TLS; this flag
  exists here only because the throwaway registry has no certificate.)
- **`crane`** and **`cosign`** on `PATH`.
- An **in-cluster registry** at `registry.registry-system.svc.cluster.local:5000`,
  reachable from the cluster by that name. Every node is configured to pull
  from it over plain HTTP.
- Two image tags in that registry, both built from the same base image so the
  *only* meaningful difference is the signature:
  - `edge-api:1.4.0` — **signed** with the playground's Cosign key.
  - `edge-api:1.4.0-untrusted` — **unsigned**.
- The **Cosign public key**, published as `configmap/cosign-pubkey` in the
  `edge` namespace (key `cosign.pub`), and also left at `/tmp/cosign.pub`. The
  private key is destroyed after signing — you only ever need the public half.
- **No `verifyImages` policy.** Writing one is the whole point of the module;
  the environment deliberately starts with nothing enforcing anything.

## Things to try

- Verify the two images by hand before involving Kyverno at all:
  `cosign verify --key /tmp/cosign.pub --allow-insecure-registry <image>` against
  the signed tag and then the unsigned one. Read the failure message closely —
  it is the same judgement Kyverno will be making on your behalf.
- Write a `verifyImages` ClusterPolicy scoped to the `edge` namespace, apply it,
  and then try creating Pods from each tag. Which one is refused, and what does
  the rejection message tell the person who hit it?
- Add `mutateDigest: true` and create a Pod from the *tag*. Inspect
  `.spec.containers[0].image` on the stored object — is it still a tag?
- Flip `required` to `false` and retry the unsigned image. Notice what quietly
  starts succeeding, and consider how you would have caught that in review.
- Deliberately corrupt one character of the public key in your policy and watch
  every verification fail. Signature checks have no partial credit.
- Scale the registry Deployment to zero (`kubectl -n registry-system scale
  deployment/registry --replicas=0`) with an `Enforce` policy active, then try
  to create a Pod. This is the availability trade-off of admission-time
  verification, demonstrated rather than described. Scale it back to `1` after.

## When you're done

```sh
astrona destroy section-040-module-02-playground
```

(`astrona destroy` takes the environment name, not the config path.)
