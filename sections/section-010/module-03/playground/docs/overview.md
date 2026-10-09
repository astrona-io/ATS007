# Overview: Mutate & Generate Rules Playground

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh` and then waits for you. There is no task, no
`astrona submit` and no pass or fail. Explore, break things, destroy it and
start again.

## What is in the box

Your playground is a training solar system with Kyverno, a source object to
clone and a Pod that is older than any policy.

- A `kind` Kubernetes cluster, context `kind-section-010-module-03-playground`.
  `kubectl` already points at it. There is no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1) in the `kyverno` namespace, with all
  four controllers running. The background controller is the one that runs
  `generate` rules, so it matters here.
- Namespace **`platform-config`**, holding a ConfigMap named
  `cluster-defaults` with three keys. It is a ready-made source for a
  `generate.clone` rule to copy from.
- Namespace **`catalog`**, holding a Pod named `existing-api` that was created
  before any policy existed. Use it as the comparison when you want to see what
  a `mutate` rule does and does not do.

No policies exist yet. Writing them is the point.

## Things to try

These ideas each take a few minutes. None of them is graded.

- Write a `mutate.patchStrategicMerge` rule that adds a label to Pods in
  `catalog`, then create a new Pod and compare it with `existing-api`. Which
  one has the label, and why?
- Express something a strategic merge cannot: use `patchesJson6902` to add an
  item at a specific list position instead of merging by name.
- Write a `generate` rule with `clone` that copies `cluster-defaults` from
  `platform-config` into every new namespace, then create a couple of
  namespaces and watch them fill in.
- Edit a generated ConfigMap by hand with `synchronize: true`, wait, and see
  what happens to your edit. Then try the same with `synchronize: false`.
- Delete the generate policy and watch what happens to the copies it made.

## When you are done

```sh
astrona destroy section-010-module-03-playground
```

`astrona destroy` takes the environment name, not the folder path.
