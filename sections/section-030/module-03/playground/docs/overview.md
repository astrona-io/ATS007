# Overview: Failure Policy, Timeouts & Resource Filters (Playground)

This is a playground, not a lab. It starts clean and waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, destroy it and start again.

## What is in the box

- A **kind** cluster, context `kind-section-030-module-03-playground`, with `kubectl` already pointed at it.
- **Kyverno v1.19.1** (Helm chart 3.9.1) with all four controllers, and **zero policies**.
- An empty `vault` namespace.

## Things to try

- Run `kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg -o yaml` and note how many webhooks it lists before any policy exists.
- Apply a policy with `failurePolicy: Ignore` and `webhookTimeoutSeconds: 20`, then read the webhook configuration again. What is new?
- Read the Kyverno settings with `kubectl get configmap kyverno -n kyverno -o yaml` and find `resourceFilters`.
- Scale `kyverno-admission-controller` to zero. Try to create a Secret that a `Fail` policy covers, and one that an `Ignore` policy covers. Scale it back up afterwards.
- Read the replica count and the disruption budget of the admission controller with `kubectl get deployment,pdb -n kyverno`.

## When you are done

```sh
astrona destroy section-030-module-03-playground
```
