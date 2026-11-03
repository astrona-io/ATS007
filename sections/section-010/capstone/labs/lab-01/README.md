---
estimated_duration: 40m
---

# Kyverno Policies & Rules Capstone Lab

Astronaut, this capstone joins validate, mutate and generate rules into one task, the kind of layered rule set a real platform team looks after.

## What is in the lab

- A `kind` Kubernetes cluster with **Kyverno v1.19.1** installed in the `kyverno` namespace.
- The `checkout` namespace, and the `platform-shared` namespace with the ConfigMap `shared-app-config`.
- No policies. Writing all three is the task.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/capstone/labs/lab-01
astrona submit -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-007-lab-004
```
