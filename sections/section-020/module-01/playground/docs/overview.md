# Overview: Kyverno Policy YAML Anatomy Playground

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh` and then waits for you. There is no task, no
`astrona submit` and no pass or fail. Explore, break things, destroy it and
start again.

## What is in the box

Your playground is a training solar system with Kyverno and two sample
manifests to test.

- A `kind` Kubernetes cluster, context `kind-section-020-module-01-playground`.
  `kubectl` already points at it. There is no SSH step and no separate
  virtual machine.
- **Kyverno v1.19.1** (Helm chart 3.9.1), installed for the whole cluster. All
  four controllers (`kyverno-admission-controller`,
  `kyverno-background-controller`, `kyverno-reports-controller`,
  `kyverno-cleanup-controller`) run in the `kyverno` namespace, so the
  `ClusterPolicy` and `Policy` kinds are registered and the admission webhook
  is live.
- Two empty namespaces (planets), `storefront` and `warehouse`, so you have
  somewhere to apply a namespaced `Policy` and somewhere it should *not*
  reach.
- Two sample manifests in `/root/playground/`: `sample-service.yaml` (a
  `LoadBalancer` Service) and `sample-pod.yaml`. Neither is applied. They are
  there to send through `kubectl apply --dry-run=server` once you have a
  policy in place.

No policies exist yet. Writing them is the point.

## Things to try

These ideas each take a few minutes. None of them is graded.

- Write a `ClusterPolicy` and the matching namespaced `Policy`, apply both,
  and work out from `kubectl get policy -A` and `kubectl get clusterpolicy`
  which objects each one can see.
- Apply a policy that blocks `type: LoadBalancer` Services, then run
  `kubectl apply --dry-run=server -f /root/playground/sample-service.yaml` and
  read the rejection message. Change the message in the policy, apply it
  again, and watch the text the user sees change.
- Take a working `validate.pattern` block and indent it one level deeper than
  the schema expects. Apply it again, run the dry run again, and see how the
  rule's behaviour changes, a mistake that costs a lot of debugging time.
- Put two policies in one file separated by `---` and apply it with a single
  `kubectl apply -f`. Then delete just one of them by name.
- Compare `kubectl apply --dry-run=client` with `--dry-run=server` on the same
  manifest and explain the difference in what each one reports.

## When you are done

```sh
astrona destroy section-020-module-01-playground
```

`astrona destroy` takes the environment name, not the folder path.
