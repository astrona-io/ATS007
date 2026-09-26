# Overview: PLAYGROUND — Validate Rules: Patterns, Deny Logic & foreach (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A kind Kubernetes cluster, context `kind-section-010-module-02-playground`.
  `kubectl` is already pointed at it — there is no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1), installed into the `kyverno` namespace, with all four
  controllers rolled out. The `background` and `reports` controllers matter
  most here: they are what produce `PolicyReport` results for resources that
  already exist.
- Two namespaces, each seeded with one Deployment that predates any policy:
  - `legacy` holds **`legacy-reporting`** — two containers, neither with
    `resources.requests` or `resources.limits`. This is what a background scan
    should flag.
  - `workloads` holds **`tidy-api`** — one container with both requests and
    limits set, so you have a passing result to compare against.

No policies are pre-created. Writing them is the point.

## Things to try

- Write a `validate.pattern` rule requiring `resources.limits.memory` and apply
  it in `Audit` mode, then work out from the `PolicyReport` whether it actually
  checked *both* containers of `legacy-reporting` or only the first.
- Rewrite the same check with `foreach` over `request.object.spec.template.spec.containers`
  and compare the two reports.
- Express something a pattern cannot: a `deny` block with `any`/`all`
  conditions that only rejects when two independent fields disagree.
- Toggle `background: false` on a policy, delete its reports, and see what
  comes back — and what does not.
- Watch the difference between admission-time and background evaluation by
  creating a brand-new violating Deployment while an `Audit` policy is live.

## When you're done

```sh
astrona destroy section-010-module-02-playground
```

(`astrona destroy` takes the environment name, not the config path.)
