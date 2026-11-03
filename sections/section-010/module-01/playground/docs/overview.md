# Overview: Kyverno Policy & Rule Anatomy Playground

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh` and then waits for you. There is no task, no
`astrona submit` and no pass or fail. Explore, break things, destroy it and
start again.

## What is in the box

Your playground is a training solar system with Kyverno ready to use.

- A `kind` Kubernetes cluster, context `kind-section-010-module-01-playground`.
  `kubectl` already points at it. There is no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1) in the `kyverno` namespace. All four
  controllers (admission, background, reports and cleanup) are running before
  the playground hands over to you.
- Three namespaces (planets) to scope rules against: `payments` (label
  `env=production`), `catalog` (label `env=staging`) and `sandbox` (no labels,
  so it is the planet a label-based rule should skip).
- One running Pod (spaceship), `sample-api` in `payments`, with the labels
  `team=payments` and `app=sample-api`.

No policies exist yet. Writing them is the point.

## Things to try

These ideas each take a few minutes. None of them is graded.

- Compare the two policy kinds: apply the same rule once as a `ClusterPolicy`
  and once as a `Policy` in `catalog`, then create a failing Pod in `sandbox`
  and see which one reacts.
- Write a rule whose `match` uses `resources.selector` on the namespace
  labels, and work out which of the three namespaces it really covers.
- Add an `exclude` block for `payments` to a rule that matches all
  namespaces, then check whether `sample-api` can still be replaced.
- Switch a policy between `validationFailureAction: Audit` and `Enforce`, and
  watch what changes for a failing Pod, and what does not.
- Ask the API server what a rule may contain:
  `kubectl explain clusterpolicy.spec.rules` shows the rule schema without
  guessing field names.

## When you are done

```sh
astrona destroy section-010-module-01-playground
```

`astrona destroy` takes the environment name, not the folder path.
