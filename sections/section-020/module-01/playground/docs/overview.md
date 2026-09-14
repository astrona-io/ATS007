# Overview: PLAYGROUND — Kyverno Policy YAML Anatomy & Applying Manifests (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A **kind** Kubernetes cluster, context `kind-section-020-module-01-playground`.
  `kubectl` is already pointed at it — there is no SSH step and no separate VM.
- **Kyverno v1.13.2**, installed cluster-wide. All four controllers
  (`kyverno-admission-controller`, `kyverno-background-controller`,
  `kyverno-reports-controller`, `kyverno-cleanup-controller`) are rolled out in
  the `kyverno` namespace, so the `ClusterPolicy` and `Policy` CRDs are
  registered and the admission webhook is live.
- Two empty namespaces, `storefront` and `warehouse`, so you have somewhere to
  apply a namespaced `Policy` and somewhere it should *not* reach.
- Two sample manifests in `/root/playground/` — `sample-service.yaml` (a
  `LoadBalancer` Service) and `sample-pod.yaml`. Neither is applied to the
  cluster; they are there to throw at `kubectl apply --dry-run=server` once you
  have a policy in place.

No policies are pre-created. Writing them is the point.

## Things to try

- Write a `ClusterPolicy` and the equivalent namespaced `Policy`, apply both,
  and work out from `kubectl get policy -A` and `kubectl get clusterpolicy`
  which resources each one can actually see.
- Apply a policy that blocks `type: LoadBalancer` Services, then run
  `kubectl apply --dry-run=server -f /root/playground/sample-service.yaml` and
  read the rejection message. Change the message in the policy, re-apply, and
  watch the text the user sees change.
- Take a working `validate.pattern` block and indent it one level deeper than
  the schema expects. Re-apply, re-run the dry-run, and see the rule quietly
  stop blocking anything — the failure mode that eats the most debugging time.
- Put two policies in one file separated by `---` and apply it in a single
  `kubectl apply -f`. Then delete just one of them by name.
- Compare `kubectl apply --dry-run=client` against `--dry-run=server` on the
  same manifest and account for the difference in what each one reports.

## When you're done

```sh
astrona destroy section-020-module-01-playground
```

(`astrona destroy` takes the environment name, not the config path.)
