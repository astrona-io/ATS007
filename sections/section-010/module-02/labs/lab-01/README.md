---
estimated_duration: 25m
---

# foreach Validate & Background Scan Lab

Astronaut, this mission checks two skills at once. You write a `foreach` rule that inspects every container of a Pod, and you read a background scan's verdict on a Deployment that was already running before your policy existed.

## What is in the lab

- A `kind` Kubernetes cluster with **Kyverno v1.19.1** installed in the `kyverno` namespace.
- The `storefront` namespace, with a running Deployment `legacy-app` that sets no CPU or memory requests or limits.
- No policies. Writing one is the task.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-02/labs/lab-01
astrona submit -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-007-lab-002
```
