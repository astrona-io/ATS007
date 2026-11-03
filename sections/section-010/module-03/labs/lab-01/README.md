---
estimated_duration: 25m
---

# Mutate & Generate Rules Lab

Astronaut, this mission checks the two rule types that change the cluster for you. You write a mutate rule that marks every new ship on one planet, and a generate rule that raises the shields on every new planet.

## What is in the lab

- A `kind` Kubernetes cluster with **Kyverno v1.19.1** installed in the `kyverno` namespace.
- The `catalog` namespace, empty and waiting.
- No policies. Writing them is the task.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-03/labs/lab-01
astrona submit -c sections/section-010/module-03/labs/lab-01
astrona destroy ats-007-lab-003
```
