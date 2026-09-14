# Part 2 — foreach & Background Scans

> Prerequisite: [Part 1 — Pattern Validation & Deny Conditions](./course-01-pattern-validation-and-deny-conditions.md). Next: [Module 3 — Mutate & Generate Rules](../module-03/course.md).

Part 1's `pattern` and `deny` both check fields you can name in advance. This part covers the two cases that breaks down for: a list whose length you don't know, and a resource that was already in the cluster before your policy existed.

## The problem with lists of unknown length

A Pod can have one container or a dozen. A pattern written against `spec.containers[0]` only ever checks the first one — the second, third, and every container after it are invisible to that pattern. There is no fixed-index pattern that safely covers "every container, however many there are."

The playground makes this concrete. Its two seeded Deployments were both created *before* any policy existed, and they are deliberate opposites: `legacy-reporting` in the `legacy` namespace violates the constraint this module keeps returning to — every container should declare CPU and memory requests and limits — while `tidy-api` in `workloads` satisfies it. The violating one also has *two* containers, which is the detail that makes `foreach` matter: a rule that inspects only one container in a two-container Pod passes something it should have caught.

> [!TIP]
> **Try it — see which containers declare resources**
>
> ```sh
> kubectl -n legacy get deploy legacy-reporting \
>   -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"\t"}{.resources}{"\n"}{end}'
> kubectl -n workloads get deploy tidy-api \
>   -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"\t"}{.resources}{"\n"}{end}'
> ```
>
> Expect something like:
>
> ```text
> api	{}
> sidecar-logger	{}
> api	{"limits":{"cpu":"200m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}
> ```
>
> Both containers of `legacy-reporting` report an empty `resources` object; `tidy-api`'s single container is fully specified. These are the two outcomes any rule you write in this module should be able to tell apart.

## `foreach`: one rule, applied per item

`foreach` solves exactly this: it iterates over a list-valued field and applies a pattern (or a deny condition) to every element in turn.

```yaml
validate:
  message: "Every container must set CPU and memory requests and limits."
  foreach:
  - list: "request.object.spec.containers"
    pattern:
      resources:
        requests:
          cpu: "?*"
          memory: "?*"
        limits:
          cpu: "?*"
          memory: "?*"
```

`list` is a JMESPath expression pointing at the array to iterate — here, every container in the incoming Pod's spec. Inside the loop, `pattern` is checked against each element (each container) independently. A Pod with five containers where only the third is missing `resources.limits.memory` still fails the rule, and Kyverno's error message identifies which element failed.

> [!TIP]
> **Try it — a multi-container failure**
>
> ```sh
> kubectl run multi --image=nginx:alpine --dry-run=client -o yaml \
>   | kubectl apply -f -
> ```
>
> A single-container Pod with no resources set will fail this rule for its one container. Add a second container by hand with resources set correctly on the first but not the second, and Kyverno's rejection message will point specifically at the failing container's index. Clean up with `kubectl delete pod multi --ignore-not-found`.

## Background scanning

Everything so far happens at admission time — when a resource is created or updated. But a cluster almost never starts empty; it already has Deployments, Pods, and other objects running before you ever write your first policy. `legacy-reporting` is exactly that case: it was created before any policy existed, so admission-time evaluation will never see it, and it is precisely the resource you most want to know about.

`background: true` addresses this. Kyverno periodically re-evaluates a validate rule against resources that already exist, independent of admission control, and records the outcome as a `PolicyReport` (namespaced) or `ClusterPolicyReport` (cluster-scoped) object.

That work is not done by the admission controller. Two separate controllers handle it, and confirming they are running is the first thing to check when reports do not appear.

> [!TIP]
> **Try it — find the controllers that produce reports**
>
> ```sh
> kubectl -n kyverno get deployments
> ```
>
> Expect something like:
>
> ```text
> NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
> kyverno-admission-controller    1/1     1            1           6m
> kyverno-background-controller   1/1     1            1           6m
> kyverno-cleanup-controller      1/1     1            1           6m
> kyverno-reports-controller      1/1     1            1           6m
> ```
>
> Ages vary. The `admission` controller handles live requests; `background` re-scans existing resources and `reports` turns those results into report objects. If a background scan result never shows up, these last two are where to look — not the admission controller.

The reports themselves are ordinary namespaced resources you query like anything else. On a fresh playground there is nothing to report yet, which makes the empty state worth seeing first so the populated state later is unambiguous.

> [!TIP]
> **Try it — the reporting surface before any policy exists**
>
> ```sh
> kubectl get policyreport --all-namespaces
> ```
>
> Expect something like:
>
> ```text
> No resources found
> ```
>
> Empty, because no policy has been applied. After you apply an `Audit`-mode policy with `background: true`, re-running this is how you find out what it made of `legacy-reporting` — without that Deployment ever being blocked, restarted, or modified.

Pairing `background: true` with `validationFailureAction: Audit` is the standard way to safely roll out a new rule: you see exactly which existing resources would fail it, without breaking anything, before ever flipping to `Enforce`.

> [!WARNING]
> **Common pitfalls**
>
> - **Assuming a check written for one container covers them all.** A Pod's `containers` field is a variable-length list, and a rule that does not explicitly iterate it can pass a Pod whose second or third container violates the constraint. `foreach` makes per-element evaluation explicit — and gives you a per-element failure message instead of one opaque verdict for the whole Pod.
> - **Expecting `background: true` to block anything.** Background scanning only ever reports. Only admission-time `Enforce` blocks, and admission control only ever sees resources at the moment they are created or updated — never resources that are just sitting there already.
> - **Reading `Audit` as "the policy is off".** An `Audit` policy is fully evaluated; it records the result rather than rejecting the request. Non-compliant resources really are being judged — the verdict just lands in a `PolicyReport` instead of in the user's terminal.
> - **Expecting background results instantly.** Background scanning runs on an interval, not on a watch. A report that is not there yet may simply not have been produced yet; give the scan time before concluding the rule is wrong.
> - **Forgetting that `background: true` restricts what a rule may reference.** A rule evaluated outside an admission request has no `AdmissionReview` to read from, so variables that depend on request-time context (such as the requesting user) are not available to it. Rules that need those must run admission-only.

> *Admission control judges what is arriving; background scanning judges what is already there — and only the first one can say no.*

## Reference

- `kubectl explain clusterpolicy.spec.rules.validate.foreach` — the live schema for `foreach` on your installed version.
- `kubectl get policyreport -o yaml` — the full structure of a background scan result, including per-rule pass/fail/warn counts.
