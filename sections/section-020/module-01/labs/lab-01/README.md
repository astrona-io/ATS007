---
estimated_duration: 15m
---

# Namespaced Policy Authoring Lab

Astronaut, this mission checks that you can write a Kyverno manifest from scratch: a namespaced `Policy`, a planet's own rule book, applied with `kubectl` and proved with one Service that is rejected and one that is admitted.

## What is in the lab

- A `kind` Kubernetes cluster with **Kyverno v1.19.1** installed in the `kyverno` namespace.
- The `storefront` namespace, empty and waiting.
- No policies. Writing one is the task.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-020/module-01/labs/lab-01
astrona submit -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-007-lab-005
```
