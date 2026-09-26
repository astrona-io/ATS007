# Overview: PLAYGROUND — Mutate & Generate Rules (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A kind Kubernetes cluster, context `kind-section-010-module-03-playground`.
  `kubectl` is already pointed at it — there is no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1), installed into the `kyverno` namespace, with all four
  controllers rolled out. The `background` controller is the one that drives
  `generate` rules, so it matters here.
- Namespace **`platform-config`**, holding a ConfigMap named
  `cluster-defaults` with three keys. This is a ready-made source for a
  `generate.clone` rule to copy from.
- Namespace **`catalog`**, holding a Pod named `existing-api` created before
  any policy exists — useful as the contrast case when you want to see what a
  `mutate` rule does and does not do.

No policies are pre-created. Writing them is the point.

## Things to try

- Write a `mutate.patchStrategicMerge` rule that adds a label to Pods in
  `catalog`, then create a new Pod and compare it against `existing-api` —
  which one has the label, and why?
- Express something a strategic merge cannot: use `patchesJson6902` to insert
  an entry at a specific array index rather than merging by key.
- Write a `generate` rule with `clone` that copies `cluster-defaults` from
  `platform-config` into every newly created namespace, then create a couple of
  namespaces and watch them fill in.
- Edit a generated ConfigMap by hand under `synchronize: true`, wait, and see
  what happens to your edit. Then try the same with `synchronize: false`.
- Delete the generate policy entirely and observe what happens to the copies it
  made.

## When you're done

```sh
astrona destroy section-010-module-03-playground
```

(`astrona destroy` takes the environment name, not the config path.)
