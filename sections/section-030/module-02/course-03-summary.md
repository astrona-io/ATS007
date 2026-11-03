# Summary

A safe rollout starts in Audit, reads the report, and only then blocks.

## What you learned

With `Enforce`, Kyverno rejects a failing request. With `Audit`, it admits the request and records the failure in a `PolicyReport` (or a `ClusterPolicyReport` for cluster-scoped objects). Results are objects, so you read them with `kubectl get policyreport`.

A policy with `background: true` also checks resources that existed before it. That work is done by `kyverno-reports-controller`, not by the admission controller. Kyverno runs four controllers: admission, background, cleanup and reports. Switching to `Enforce` never touches a resource that is already running.

The key facts to remember are these:

- Audit records, Enforce blocks.
- Background scans find old violations; admission finds new ones.
- A missing report points at the reports controller or at `background: false`.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Audit-to-Enforce Rollout Lab](./labs/lab-01/README.md) | Background Scanning & Controllers | Roll out in Audit, read the report and switch to Enforce |

## Check yourself

<details>
<summary>1. A policy is in Audit and a Pod breaks it. What happens?</summary>

The Pod is created and the failure is recorded in a `PolicyReport`.
</details>

<details>
<summary>2. Which controller writes the reports for old resources?</summary>

`kyverno-reports-controller`.
</details>

<details>
<summary>3. You switch a policy to Enforce. What happens to a running violator?</summary>

Nothing. Only new requests are judged.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-030-module-02-playground
astrona destroy ats-007-lab-009
```

> *Audit tells you who is inside. Enforce guards the door.*

<!-- astrona:playground:destroy -->
