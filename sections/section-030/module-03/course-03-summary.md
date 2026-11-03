# Summary

Kyverno has dials for what happens when it is silent, and a list of objects it never checks. Together they decide how safe a policy is in a real outage.

## What you learned

`spec.failurePolicy` is `Fail` (default) or `Ignore`, and `spec.webhookTimeoutSeconds` is 1 to 30 seconds (default 10). Kyverno writes each policy's rules into a webhook that matches its failure policy, so the configuration holds a `-fail` and an `-ignore` webhook. The settings only matter when Kyverno cannot answer. While it is healthy, both kinds of policy block the same objects.

`resourceFilters` in the `kyverno` ConfigMap lists objects Kyverno skips. The webhook also keeps the `kyverno` namespace out of reach. More replicas and a `PodDisruptionBudget` keep the admission controller available. The key facts to remember are these:

- `Fail` blocks matching requests when Kyverno is down; `Ignore` admits them.
- A filtered kind never reaches a policy.
- Both policy dials sit under `spec`.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Failure Policy Lab](./labs/lab-01/README.md) | Failure policy and timeouts | Set `Ignore` and a timeout, read them in the webhook, and prove the rule still blocks |

## Check yourself

<details>
<summary>1. Kyverno is down and a policy has failurePolicy Ignore. What happens to a matching request?</summary>

The API server admits it without a check.
</details>

<details>
<summary>2. Where do you set how long the API server waits for Kyverno?</summary>

`spec.webhookTimeoutSeconds` on the policy. It must be between 1 and 30.
</details>

<details>
<summary>3. A policy never fires for a kind. What setting do you check first?</summary>

The `resourceFilters` list in the `kyverno` ConfigMap, then the `match` block.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-030-module-03-playground
astrona destroy ats-007-lab-017
```

> *When the gate keeper sleeps, the dial decides: open or shut.*

<!-- astrona:playground:destroy -->
