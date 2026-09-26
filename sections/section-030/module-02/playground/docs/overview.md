# Overview: PLAYGROUND — Kyverno as a Dynamic Admission Controller (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A **kind** Kubernetes cluster, context `kind-section-030-module-02-playground`.
  `kubectl` is already pointed at it — there is no VM and no SSH step.
- **Kyverno v1.19.1** (Helm chart 3.9.1), installed cluster-wide by `bootstrap/prepare.sh`, with all
  four controllers running in the `kyverno` namespace. The
  `PolicyReport`/`ClusterPolicyReport` CRDs are registered and ready to be
  populated.
- **Zero policies**, so the first `PolicyReport` you see is one your own policy
  produced.
- An **`analytics`** namespace containing a running `legacy-etl` Deployment
  (`nginx`) with **no `cost-center` label**. It was created before any policy
  existed — which is exactly the situation background scanning is designed to
  catch, and admission control cannot.

## Things to try

- Look for `PolicyReport` objects before installing anything
  (`kubectl get policyreport -A`), then install an `Audit`-mode policy requiring
  a `cost-center` label on Deployments and watch reports appear for the
  already-running `legacy-etl` without anything being blocked.
- Flip that same policy's `validationFailureAction` from `Audit` to `Enforce` and
  confirm the running `legacy-etl` Deployment keeps running untouched, while a
  *new* non-compliant Deployment is now rejected at creation.
- Set `background: false` on a policy, delete its existing reports, and see which
  results stop being produced — and which still appear from admission events.
- Compare `kubectl get policyreport -A` (namespaced results) with
  `kubectl get clusterpolicyreport` (results for cluster-scoped resources) and
  work out which kind of resource lands in which.
- Trace a symptom to the right controller: stop `kyverno-reports-controller`
  (scale it to zero), create a new violation, and observe which evidence
  disappears and which still works. Scale it back up afterwards.

## When you're done

```sh
astrona destroy section-030-module-02-playground
```

(`astrona destroy` takes the environment name, not the config path.)
