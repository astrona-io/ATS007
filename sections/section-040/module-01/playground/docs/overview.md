# Overview: PLAYGROUND — OCI Image Fundamentals & Supply Chain Risk (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A **kind Kubernetes cluster** (context `kind-section-040-module-01-playground`),
  with `kubectl` already pointed at it. There is no SSH step and no VM — you
  work against the cluster directly.
- **Kyverno v1.19.1** (Helm chart 3.9.1), installed in the `kyverno` namespace. This module does
  not write a policy, but Kyverno is present so you can look at how it is
  deployed before Module 2 puts it to work.
- **`crane`** (from `go-containerregistry`) on `PATH` — a small registry client
  for asking a registry what a tag currently resolves to, without pulling the
  image or needing a running Pod.
- A sample **`edge-api` Deployment** in the `edge` namespace, deliberately
  referencing the *mutable tag* `docker.io/library/nginx:1.25-alpine`. It exists
  so you have a real running workload whose tag and digest you can compare.

## Things to try

- Compare what the Deployment spec says it wants against what the kubelet
  actually pulled. `kubectl -n edge describe pod` shows both `Image:` and
  `Image ID:` — decide for yourself which one you would trust in an incident.
- Ask the registry directly what several tags of the same repository resolve
  to (`crane digest docker.io/library/nginx:1.25-alpine`, then `:alpine`, then
  `:latest`). Which ones point at the same manifest right now? Would you expect
  that to still be true next month?
- Pull a manifest apart with `crane manifest <image>` and find the config blob
  and layer blobs it references. Every entry is a digest — try `crane config`
  on the same image to see the runtime metadata the config blob holds.
- Edit the Deployment to reference the image by digest instead of by tag
  (`kubectl -n edge edit deployment edge-api`), then check whether `Image:` and
  `Image ID:` still disagree. This is digest pinning, done by hand.
- Delete the Pod and let the Deployment recreate it. Does `Image ID:` change?
  Should it, given the tag was not repointed in between?

## When you're done

```sh
astrona destroy section-040-module-01-playground
```

(`astrona destroy` takes the environment name, not the config path.)
