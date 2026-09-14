# Overview: PLAYGROUND — The Kubernetes Admission Control Model (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A **kind** Kubernetes cluster, context `kind-section-030-module-01-playground`.
  `kubectl` is already pointed at it — there is no VM and no SSH step.
- **Kyverno v1.13.2**, installed cluster-wide by `bootstrap/prepare.sh`. All four
  controllers (`kyverno-admission-controller`, `kyverno-background-controller`,
  `kyverno-reports-controller`, `kyverno-cleanup-controller`) are running in the
  `kyverno` namespace, and Kyverno's `MutatingWebhookConfiguration` and
  `ValidatingWebhookConfiguration` objects are registered with the API server.
- **Zero policies.** The cluster deliberately starts with no `ClusterPolicy` or
  `Policy` installed, so you can watch Kyverno's webhook `rules` grow and shrink
  as you add and remove policies yourself.
- A scratch **`demo`** namespace for throwaway resources.

## Things to try

- Read both of Kyverno's webhook configuration objects
  (`kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations`)
  and compare their `rules` lists on this policy-free cluster against what you
  would expect after installing a policy.
- Write a trivial `ClusterPolicy` matching a single kind — `ConfigMap` is a good
  choice — apply it, then re-read the validating webhook a few seconds later and
  find the rule entry that appeared. Delete the policy and watch it disappear.
- Find where the API server's *built-in* admission plugins are configured:
  `kubectl -n kube-system get pod -l component=kube-apiserver -o yaml` and look
  for `--enable-admission-plugins`. Compare that compiled-in list against the
  dynamic webhooks Kyverno registered.
- Flip a webhook's `failurePolicy` between `Fail` and `Ignore` by editing the
  Kyverno configuration, then scale `kyverno-admission-controller` to zero
  replicas and observe what happens to matching requests. Scale it back up when
  you are done.
- Compare `timeoutSeconds` and `namespaceSelector` across Kyverno's webhooks and
  work out which namespaces are exempt from interception by default, and why
  those particular ones.

## When you're done

```sh
astrona destroy section-030-module-01-playground
```

(`astrona destroy` takes the environment name, not the config path.)
