# Summary

Every write to the cluster passes an ordered pipeline, and Kyverno joins it through webhooks that it manages itself.

## What you learned

A write request passes authentication, authorization, mutating admission, schema validation, validating admission and then etcd. Mutation always finishes before validation starts. Built-in controllers are compiled into the API server. Dynamic webhooks are separate programs the API server calls over the network.

Kyverno's `kyverno-admission-controller` answers those calls. A webhook configuration holds `rules`, `failurePolicy`, `namespaceSelector` and `timeoutSeconds`. Kyverno rewrites its own configuration as policies come and go, so a kind appears in the webhook rules only when a policy matches it.

The key facts to remember are these:

- Mutating webhooks run before schema validation, and validating webhooks run last.
- `failurePolicy: Fail` blocks requests when Kyverno is down; `Ignore` admits them.
- Kyverno adds and removes webhook rules for you.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Auto-Managed Webhook Configuration Lab](./labs/lab-01/README.md) | Mutating vs Validating Webhooks | Install a ConfigMap policy and find its rule appear in the live webhook |

## Check yourself

<details>
<summary>1. At which stage can a webhook still rewrite an object?</summary>

During mutating admission, which comes before schema validation and validating admission.
</details>

<details>
<summary>2. Which Kyverno Deployment answers the API server's calls?</summary>

`kyverno-admission-controller`.
</details>

<details>
<summary>3. You apply a policy for ConfigMaps. What changes in the validating webhook?</summary>

Kyverno adds a rule entry for `configmaps` to its webhook configuration.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-030-module-01-playground
astrona destroy ats-007-lab-008
```

> *The pipeline is a corridor, and Kyverno is one of its doors.*

<!-- astrona:playground:destroy -->
