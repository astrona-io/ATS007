# Background Scanning & Controllers

Admission control only ever sees a resource at the moment it is created or updated. A Deployment that already existed in the cluster a year before your new policy was installed will never pass through that policy's webhook again on its own — nothing about it is being created or updated. Without another mechanism, that old Deployment would silently escape every new policy you write.

## The violation that was already there

A report can name a specific resource, and it is worth looking at directly, because it is the situation that makes this whole mechanism necessary. The playground's `analytics` namespace contains a Deployment called `legacy-etl` that carries no `cost-center` label. It was created *before* any policy existed, and it is running right now.

Admission control cannot help you here, and not because of a configuration mistake. Admission webhooks are only consulted when a resource is being created or updated. Nothing is creating or updating `legacy-etl` — it is simply sitting there. A policy you install this afternoon will never see it pass through the webhook at all.

> [!TIP]
> **Try it — find the workload that predates every policy**
>
> ```sh
> kubectl get deployments -n analytics --show-labels
> ```
>
> Expect something like:
>
> ```text
> NAME         READY   UP-TO-DATE   AVAILABLE   AGE   LABELS
> legacy-etl   1/1     1            1           6m    app=legacy-etl
> ```
>
> Note what is *absent*: there is no `cost-center` label. Ages and the exact label set vary. This is the resource a `fail` result entry points at.

## Background scanning closes that gap

Setting `background: true` on a policy (the default for `validate` rules) tells Kyverno to periodically re-evaluate *existing* resources against the rule, independent of admission events, and record the results as `PolicyReport`/`ClusterPolicyReport` entries. This is what let `legacy-etl` show up in a report even though nobody re-applied it after the policy was installed.

Background scanning only ever produces **report entries** — it cannot retroactively block or delete a resource that already exists and violates a policy that is now `Enforce`. Enforce mode only stops *new* violations at the door; background scanning is how you find violations that got in before the door existed.

Because the behaviour depends entirely on that one field, it is the first thing to check when a long-running resource is missing from a report.

> [!TIP]
> **Try it — confirm a policy is set to scan existing resources**
>
> ```sh
> kubectl get clusterpolicy require-cost-center-label -o jsonpath='{.spec.background}{"\n"}'
> ```
>
> Expect `true`. If a policy needs to skip background scanning entirely (some `mutate`/`generate` rules depend on live admission-request context that isn't available during a background pass), you will see `false` here instead — and its report will only ever cover resources admitted since it was installed.

## The four controllers

Since Kyverno 1.10 (the "chainsaw" architecture split), what used to be one monolithic pod is four separate controllers, each running in the `kyverno` namespace with its own `Deployment`. Knowing which one does what matters directly for troubleshooting:

| Controller | Responsible for |
| --- | --- |
| `kyverno-admission-controller` | Serves the `MutatingWebhookConfiguration`/`ValidatingWebhookConfiguration` HTTPS endpoints. Handles real-time `mutate`, `validate`, and `verifyImages` rule evaluation at admission time. |
| `kyverno-background-controller` | Drives `generate` rule processing and mutate-existing (`mutateExistingOnPolicyUpdate`) background work. |
| `kyverno-reports-controller` | Runs the periodic background scans described above and writes/aggregates `PolicyReport`/`ClusterPolicyReport` objects. |
| `kyverno-cleanup-controller` | Executes `CleanupPolicy`/`ClusterCleanupPolicy` TTL-based deletion of matching resources on a schedule. |

```mermaid
flowchart LR
    A[kyverno-admission-controller] -->|real-time mutate/validate/verifyImages| B[Admission requests]
    C[kyverno-background-controller] -->|generate + mutate-existing| D[Cluster resources]
    E[kyverno-reports-controller] -->|periodic scans| F[PolicyReport / ClusterPolicyReport]
    G[kyverno-cleanup-controller] -->|scheduled deletes| H[CleanupPolicy targets]
```

This split has a concrete consequence for the report for `legacy-etl`: it was not written by the admission controller. The admission controller was never involved at all, because `legacy-etl` was never re-admitted. The report came from `kyverno-reports-controller`.

That distinction is the whole troubleshooting heuristic. A missing report for a long-running resource is a reports-controller question; a resource that should have been blocked but was not is an admission-controller question. Reading the wrong component's logs is the most common way to waste an hour here.

> [!TIP]
> **Try it — identify the controller that produced the report**
>
> ```sh
> kubectl get deployment -n kyverno kyverno-reports-controller
> ```
>
> Expect something like:
>
> ```text
> NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
> kyverno-reports-controller   1/1     1            1           8m
> ```
>
> If reports ever stop appearing for existing resources, this is the Deployment whose health and logs are relevant — `kubectl logs -n kyverno deployment/kyverno-reports-controller`. Ages and replica counts vary with the install.

## See it in your playground

<!-- astrona:playground:renew -->

List the four Kyverno controllers and see which Pods back them:

```sh
kubectl get deployments -n kyverno
```

You see `kyverno-admission-controller`, `kyverno-background-controller`, `kyverno-cleanup-controller` and `kyverno-reports-controller`. The reports controller writes the `PolicyReport` objects, and the admission controller answers the API server. Now read all reports on the cluster:

```sh
kubectl get policyreport -A
```

The `legacy-etl` result in `analytics` came from a background scan, not from an admission request, because the Deployment was created before the policy. Switch the policy to `Enforce` and check that `legacy-etl` stays untouched while a new Deployment without the label is rejected:

```sh
kubectl patch clusterpolicy require-cost-center-label --type merge -p '{"spec":{"validationFailureAction":"Enforce"}}'
kubectl create deployment legacy-etl-v2 --image=nginx -n analytics
```

The patch needs the `require-cost-center-label` `ClusterPolicy` applied, which checks Deployments in `analytics` for a `cost-center` label.

## Your mission: Audit-to-Enforce Rollout Lab

You can now do the skill this part teaches on a live cluster. The mission asks you to do it again on a fresh one.

First pause the playground:

```sh
astrona stop section-030-module-02-playground
```

Then run the mission and submit your work:

```sh
astrona run --git git@github.com:astrona-io/ATS007.git -c sections/section-030/module-02/labs/lab-01
astrona submit
```

When you are done, remove the mission and start the playground again:

```sh
astrona destroy ats-007-lab-009
astrona start section-030-module-02-playground
```

> [!WARNING]
> **Common pitfalls**
>
> - **Debugging a missing report in the admission controller's logs.** For a resource that has existed for weeks, the admission controller has no record of it and never will — the resource was never re-admitted. Missing background-scan results point at `kyverno-reports-controller`, or at a policy with `background: false`.
> - **Expecting background scanning to fix anything.** It reports; it does not block, evict, patch, or delete. Finding the violation is automatic, remediating it is not.
> - **Assuming a report appears the instant a policy is applied.** Background scans run on an interval, not on a trigger. A report that is not there yet is frequently just a report that is not there *yet*.

> *Admission control guards the door; background scanning tells you who was already inside.*
