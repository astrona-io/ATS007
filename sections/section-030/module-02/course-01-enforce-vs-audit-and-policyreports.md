# Part 1 — Enforce vs Audit & PolicyReports

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Background Scanning & Controllers](./course-02-background-scanning-and-controllers.md).

Every Kyverno `validate` rule runs under one of two modes, set by `spec.validationFailureAction` on the policy (or overridden per-rule):

- **`Enforce`** — a rule failure means the validating webhook responds `allowed: false`. The API server rejects the request outright. The client sees an error, and nothing is written to etcd.
- **`Audit`** — a rule failure still lets the request through (`allowed: true`), but Kyverno records the failure as a result in a `PolicyReport` (namespaced) or `ClusterPolicyReport` (for cluster-scoped resources like Namespaces or PersistentVolumes).

Nothing about the rule's `match`/`validate` logic changes between the two modes — only what happens once the rule evaluates to "fail."

## Results are objects, not log lines

When Kyverno evaluates a resource and the result is worth recording, it does not write a line to a log file you would have to scrape. It creates or updates a Kubernetes object: a `PolicyReport` for namespaced resources, a `ClusterPolicyReport` for cluster-scoped ones. Both are CRDs registered at install time, and both behave like any other resource — `get` them, filter them with selectors, watch them, feed them to a dashboard.

That design choice is what makes Audit mode operationally useful rather than merely quiet. "Which of my 400 workloads would this policy have blocked?" becomes a query instead of an investigation.

> [!TIP]
> **Try it — confirm the reporting API exists, and that nothing has produced one yet**
>
> ```sh
> kubectl api-resources | grep -i policyreport
> kubectl get policyreport -A
> ```
>
> Expect something like:
>
> ```text
> policyreports        polr    wgpolicyk8s.io/v1alpha2   true    PolicyReport
> clusterpolicyreports cpolr   wgpolicyk8s.io/v1alpha2   false   ClusterPolicyReport
>
> No resources found
> ```
>
> The CRDs are registered and ready, but empty — reports are produced by policies, and this cluster has none yet. The API group (`wgpolicyk8s.io`) is a shared open standard, not Kyverno-specific, which is why third-party tooling can read these reports.

## The Audit-then-Enforce workflow

Because `PolicyReport` gives you a dry-run of enforcement across the whole fleet, the standard operational sequence for rolling out any new Kyverno policy is:

1. Author the policy with `validationFailureAction: Audit` and `background: true`.
2. Deploy it. Wait for the background scan to complete (Part 2 covers this).
3. Review `PolicyReport`/`ClusterPolicyReport` results across every namespace the policy applies to.
4. Fix non-compliant resources, or refine the policy if the reports reveal it was too strict or matched the wrong resources.
5. Once reports are clean (or the remaining failures are accepted/tracked), flip `validationFailureAction` to `Enforce`.

Skipping straight to `Enforce` on a cluster with existing resources is the single most common way a new Kyverno policy causes an unplanned outage — a policy that looks correct in isolation can reject a deploy pipeline the moment it meets resources it was never tested against.

Step 1 is worth doing for real. The policy below requires a `cost-center` label on Deployments in the `analytics` namespace, in Audit mode. Applying it changes cluster state: it creates a `ClusterPolicy` and, shortly after, report objects. Nothing is blocked and no workload is modified. To undo everything, delete the policy — its reports are garbage-collected with it.

> [!TIP]
> **Try it — install an Audit policy and watch a report appear for a running workload**
>
> ```sh
> kubectl apply -f - <<'EOF'
> apiVersion: kyverno.io/v1
> kind: ClusterPolicy
> metadata:
>   name: require-cost-center-label
> spec:
>   validationFailureAction: Audit
>   background: true
>   rules:
>     - name: check-cost-center-label
>       match:
>         any:
>           - resources:
>               kinds:
>                 - Deployment
>               namespaces:
>                 - analytics
>       validate:
>         message: "Deployments must carry a cost-center label."
>         pattern:
>           metadata:
>             labels:
>               cost-center: "?*"
> EOF
>
> # background scans are periodic - give the reports controller a moment
> kubectl get policyreport -n analytics
> ```
>
> Expect something like:
>
> ```text
> clusterpolicy.kyverno.io/require-cost-center-label created
>
> NAME                             PASS   FAIL   WARN   ERROR   SKIP   AGE
> cpol-require-cost-center-label   0      1      0      0       0      20s
> ```
>
> Counts and age vary with what else is running in the namespace, and the report may take a scan interval to appear. The columns are the point: `FAIL 1` against a Deployment that is still `READY 1/1` is Audit mode's whole thesis — the violation is now visible and measurable, and nothing broke. Remove it all with `kubectl delete clusterpolicy require-cost-center-label`.

## Reading a PolicyReport

The summary columns tell you *how many* results there are. To act on them you need to know which resource failed which rule and why, which means reading the report object itself. Kyverno populates it with one result entry per resource per rule evaluated, whether that evaluation happened at admission time or during a background scan (covered in Part 2).

Report objects for a `ClusterPolicy` are named `cpol-<policy-name>`, so the report produced above is `cpol-require-cost-center-label`:

```sh
kubectl get policyreport -n analytics cpol-require-cost-center-label -o yaml
```

```text
results:
- policy: require-cost-center-label
  rule: check-cost-center-label
  resources:
  - apiVersion: apps/v1
    kind: Deployment
    name: legacy-etl
    namespace: analytics
  result: fail
  message: "validation error: Deployments must carry a 'cost-center' label. rule
    check-cost-center-label failed at path /metadata/labels/cost-center/"
```

The resource named here, `legacy-etl`, was already running in `analytics` before the policy existed and carries no `cost-center` label. Part 2 explains why a resource that never passed through the webhook again still ended up in this report.

This is the entire value proposition of Audit mode: you get the exact list of resources a policy *would* have blocked, without blocking a single one of them, before you commit to `Enforce`.

> [!TIP]
> **Try it — pull out just the failing result entries**
>
> ```sh
> kubectl get policyreport -n analytics -o json | jq '.items[].results[] | select(.result=="fail")'
> ```
>
> Expect a `fail` result entry naming the specific Deployment and rule that produced it, matching the shape shown above. Field rendering varies slightly with your `kubectl`/`jq` version, but `result` and `message` are always present. Filtering server-side output this way is how you turn a fleet-wide report set into a work list.

> [!WARNING]
> **Common pitfalls**
>
> - **Reading `Audit` as "the policy is off".** An Audit policy is fully evaluated on every matching admission request and every background scan; the only thing it declines to do is reject. It does not disable the rule and it does not mean "no output" — treating it as disabled means ignoring a live, accurate inventory of exactly what would break under `Enforce`.
> - **Expecting `Enforce` to clean up what is already running.** Flipping a policy to `Enforce` stops *new* non-compliant resources at admission. It does not touch, evict, or fix resources admitted before the policy existed — `legacy-etl` keeps running regardless. Existing violations are found by background scanning and fixed by you.

> *Audit does not mean off — it means evaluated, recorded, and not yet blocking.*

## Reference

- `kubectl explain clusterpolicy.spec.validationFailureAction` — confirms the two accepted values on the installed CRD.
- Kyverno documentation: "Policy Reports" — the full schema of `PolicyReport`/`ClusterPolicyReport`, including the `summary` field that totals pass/fail/warn/error/skip counts.
