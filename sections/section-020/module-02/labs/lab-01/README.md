---
estimated_duration: 25m
---

# Context & Variables Validation Lab

Astronaut, this mission checks that a rule can read outside data. You load an allow-list from a ConfigMap with a `context` entry, compare a Pod's label against it with variables and JMESPath, and name the refused value in the rejection message.

## What is in the lab

- A `kind` Kubernetes cluster with **Kyverno v1.19.1** installed in the `kyverno` namespace.
- The `releases` namespace, with the ConfigMap `allowed-environments` (`values: dev,staging,prod`).
- No policies. Writing one is the task.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-020/module-02/labs/lab-01
astrona submit -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-007-lab-006
```
