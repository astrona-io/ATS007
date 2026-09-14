# Overview: PLAYGROUND — Validating Manifests with the Kyverno CLI (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A **kind** Kubernetes cluster, context `kind-section-020-module-03-playground`.
  `kubectl` is already pointed at it — there is no SSH step and no separate VM.
- **Kyverno v1.13.2** installed in-cluster, all four controllers rolled out in
  the `kyverno` namespace. Most of this module never touches it — it is here so
  you can compare offline evaluation against real admission behaviour.
- The **`kyverno` CLI v1.13.2** at `/usr/local/bin/kyverno`, installed for the
  node's architecture (amd64 or arm64). This is the standalone binary the module
  is about; it needs no cluster.
- Sample files in `/root/playground/`:
  - `disallow-latest-tag.yaml` — a `ClusterPolicy` rejecting `:latest` images.
  - `pinned-pod.yaml` — a Pod that should pass it.
  - `latest-pod.yaml` — a Pod that should fail it.
  - `sample.json` — a small JSON document to practise `kyverno jp query` on.

No `kyverno-test.yaml` is seeded. Writing one is the point.

## Things to try

- Run `kyverno apply` with the seeded policy against each Pod manifest in turn,
  then check `echo $?` after each — that exit code is the whole basis for using
  the CLI as a CI gate.
- Write a `kyverno-test.yaml` declaring the expected outcome for both Pods and
  run `kyverno test .`. Then deliberately invert one expectation and watch the
  suite catch you.
- Point `kyverno jp query` at `sample.json` and build up an expression that
  extracts every container image as a list. Compare it to what you would have to
  write as a `pattern` block.
- Evaluate the same policy two ways — offline with `kyverno apply`, and against
  the live cluster with `kubectl apply --dry-run=server` — and confirm they
  agree. Then find a case where they could not agree (hint: anything the policy
  needs `context` for).
- Break the policy's indentation so the `pattern` sits one level too deep,
  re-run `kyverno apply`, and see how the CLI reports a rule that now asserts
  nothing.

## When you're done

```sh
astrona destroy section-020-module-03-playground
```

(`astrona destroy` takes the environment name, not the config path.)
