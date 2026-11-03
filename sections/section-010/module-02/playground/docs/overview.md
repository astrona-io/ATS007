# Overview: Validate Rules Playground

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh` and then waits for you. There is no task, no
`astrona submit` and no pass or fail. Explore, break things, destroy it and
start again.

## What is in the box

Your playground is a training solar system with Kyverno and two Deployments
that were flying before any policy existed.

- A `kind` Kubernetes cluster, context `kind-section-010-module-02-playground`.
  `kubectl` already points at it. There is no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1) in the `kyverno` namespace, with all
  four controllers running. The background and reports controllers matter
  most here: they write `PolicyReport` results (the inspection log) for
  objects that already exist.
- Two namespaces (planets), each with one Deployment:
  - `legacy` holds **`legacy-reporting`**: two containers (`api` and
    `sidecar-logger`), neither with `resources.requests` or
    `resources.limits`. A background scan should flag it.
  - `workloads` holds **`tidy-api`**: one container with both requests and
    limits set, so you have a passing result to compare against.

No policies exist yet. Writing them is the point.

## Things to try

These ideas each take a few minutes. None of them is graded.

- Write a `validate.pattern` rule that requires `resources.limits.memory`,
  apply it in `Audit` mode, then work out from the `PolicyReport` whether it
  checked *both* containers of `legacy-reporting` or only the first.
- Rewrite the same check with `foreach` over
  `request.object.spec.template.spec.containers` and compare the two reports.
- Express something a pattern cannot: a `deny` block with `any` or `all`
  conditions that only rejects when two separate fields disagree.
- Set `background: false` on a policy, delete its reports, and see what comes
  back, and what does not.
- See the difference between admission and background checks: create a new
  failing Deployment while an `Audit` policy is active.

## When you are done

```sh
astrona destroy section-010-module-02-playground
```

`astrona destroy` takes the environment name, not the folder path.
