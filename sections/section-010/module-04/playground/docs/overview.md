# Overview: Autogen & Policy Exceptions (Playground)

This is a playground, not a lab. It starts clean and waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, destroy it and start again.

## What is in the box

- A **kind** cluster, context `kind-section-010-module-04-playground`, with `kubectl` already pointed at it.
- **Kyverno v1.19.1** (Helm chart 3.9.1), installed with policy exceptions switched on (`features.policyExceptions.enabled=true`).
- An empty `shop` namespace and **zero policies**.

## Things to try

- Apply a `ClusterPolicy` that matches only `Pod`, then run `kubectl get clusterpolicy <name> -o yaml` and look at the annotations Kyverno adds.
- Create a Deployment that breaks the rule and read the denial message. Which rule name does it quote?
- Add the annotation `pod-policies.kyverno.io/autogen-controllers: none` and repeat. What changes?
- Write a `PolicyException` for one Pod name and prove a second Pod is still blocked.
- Delete the `PolicyException` and prove the first Pod is blocked again.

## When you are done

```sh
astrona destroy section-010-module-04-playground
```
