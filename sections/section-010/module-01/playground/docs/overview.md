# Overview: PLAYGROUND — Kyverno Policy & Rule Anatomy (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A kind Kubernetes cluster, context `kind-section-010-module-01-playground`.
  `kubectl` is already pointed at it — there is no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1), installed into the `kyverno` namespace. All four
  controllers (`admission`, `background`, `reports`, `cleanup`) are rolled out
  and ready before the environment hands over to you.
- Three namespaces to scope rules against: `payments` (labelled
  `env=production`), `catalog` (labelled `env=staging`), and `sandbox` (no
  labels — useful as the namespace a selector-based rule should *skip*).
- One running Pod, `sample-api` in `payments`, labelled `team=payments` and
  `app=sample-api`.

No policies are pre-created. Writing them is the point.

## Things to try

- Compare the two policy kinds side by side: apply the same rule once as a
  `ClusterPolicy` and once as a `Policy` in `catalog`, then create a violating
  Pod in `sandbox` and see which one reacts.
- Write a rule whose `match` uses `resources.selector` against the namespace
  labels, and work out which of the three namespaces it actually covers.
- Add an `exclude` block for `payments` to a rule that matches all namespaces,
  then check whether `sample-api` can still be replaced.
- Flip a policy between `validationFailureAction: Audit` and `Enforce` and
  watch what changes for a non-compliant Pod — and what does not.
- Ask the API server what the CRDs allow: `kubectl explain clusterpolicy.spec.rules`
  walks the rule schema without you having to guess a field name.

## When you're done

```sh
astrona destroy section-010-module-01-playground
```

(`astrona destroy` takes the environment name, not the config path.)
