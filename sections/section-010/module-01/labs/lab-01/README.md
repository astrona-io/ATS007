---
estimated_duration: 15m
---

# ClusterPolicy Label Enforcement Lab

Astronaut, this mission checks the first skill every Kyverno user needs: writing a rule book (a `ClusterPolicy`), aiming it at exactly the right ships with `match` and `exclude`, and proving that it blocks a Pod without a required label.

## What is in the lab

- A `kind` Kubernetes cluster with **Kyverno v1.19.1** installed in the `kyverno` namespace.
- The `payments` namespace, empty and waiting.
- No policies. Writing one is the task.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-007-lab-001
```
