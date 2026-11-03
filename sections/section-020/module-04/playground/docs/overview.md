# Overview: Policy Packaging: Metadata & Kustomize (Playground)

This is a playground, not a lab. It starts clean and waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, destroy it and start again.

## What is in the box

- A **kind** cluster, context `kind-section-020-module-04-playground`, with `kubectl` already pointed at it.
- **Kyverno v1.19.1** (Helm chart 3.9.1) with zero policies.
- A working folder `/root/playground` with `base/` (a `ClusterPolicy` and a `kustomization.yaml`) and an empty `overlays/prod/` folder.

## Things to try

- Run `kubectl kustomize base` and compare the output with the file on disk.
- Apply the base with `kubectl apply -k base`, then read its annotations with `kubectl get clusterpolicy require-owner-label -o jsonpath='{.metadata.annotations}'`.
- Write an overlay in `overlays/prod` that raises the severity annotation and switches the policy to `Enforce`, then run `kubectl diff -k overlays/prod`.
- Add a label to every object in the overlay with the `labels` field of the `kustomization.yaml`.
- Break the overlay on purpose (point `resources` at a missing folder) and read the error from `kubectl kustomize`.

## When you are done

```sh
astrona destroy section-020-module-04-playground
```
