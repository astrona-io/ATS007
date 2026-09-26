# Part 1 — ClusterPolicy vs Policy & Rule Anatomy

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Match, Exclude & Resource Selection](./course-02-match-exclude-and-resource-selection.md).

This part settles what a Kyverno policy *is* as an object, which of the two policy kinds to reach for, and how the `rules` list inside one is put together. Part 2 builds directly on the `match` block sketched here.

## Policies are Kubernetes resources

Install Kyverno onto a cluster and it registers a handful of Custom Resource Definitions (CRDs), the two most important being `ClusterPolicy` and `Policy`. Both are ordinary Kubernetes objects: they live in etcd, they show up in `kubectl get`, and — critically — they are watched by Kyverno's own controllers, which turn them into live admission-control behavior.

This matters more than it sounds. It means a Kyverno policy can be:

- Reviewed in a pull request, next to the workload manifests it governs.
- Applied with the exact same tooling (`kubectl`, Helm, Argo CD, Flux) you already use for everything else.
- Read by anyone who already knows YAML and the Kubernetes resource model — no Rego, no Cedar, no separate expression language to learn.

There is a practical payoff beyond convenience. Because the API server holds the schema for these CRDs, you do not need Kyverno-specific tooling to discover what a rule may contain — `kubectl explain` walks the same schema the API server validates against.

> [!TIP]
> **Try it — read the rule schema straight from the cluster**
>
> ```sh
> kubectl explain clusterpolicy.spec.rules --recursive | head -20
> ```
>
> Expect something like:
>
> ```text
> GROUP:      kyverno.io
> KIND:       ClusterPolicy
> FIELDS:
>   match     <Object>
>   exclude   <Object>
>   validate  <Object>
>   mutate    <Object>
>   ...
> ```
>
> The exact field list and ordering vary by Kyverno version. The point is that the rule schema is discoverable from the cluster itself — when you are unsure whether a field exists on the version you are running, this answers it authoritatively.

## ClusterPolicy vs Policy

Kyverno gives you two kinds of policy resource, and the choice between them is purely about scope:

| Kind | Scope | Typical use |
| --- | --- | --- |
| `ClusterPolicy` | Cluster-wide — its rules can match resources in any namespace (or cluster-scoped resources) unless you narrow them | Organization-wide guardrails: "every Pod everywhere must set resource limits" |
| `Policy` | Namespace-scoped — lives inside one namespace, and its rules can only ever match resources in that same namespace | Team- or tenant-specific rules a namespace owner controls themselves |

Both kinds share the exact same `spec` structure underneath — the same `rules`, `match`, `exclude`, and action blocks you'll see below. The only difference is where the object itself lives and how far its authority reaches.

That scope difference is not just documentation; it is recorded in the API registration itself, in the `NAMESPACED` column.

> [!TIP]
> **Try it — see both kinds registered**
>
> ```sh
> kubectl api-resources --api-group=kyverno.io
> ```
>
> Expect something like:
>
> ```text
> NAME                 SHORTNAMES   APIVERSION      NAMESPACED   KIND
> cleanuppolicies      cleanpol     kyverno.io/v2   true         CleanupPolicy
> clusterpolicies      cpol         kyverno.io/v1   false        ClusterPolicy
> policies             pol          kyverno.io/v1   true         Policy
> ```
>
> The exact CRD list varies by Kyverno version. `clusterpolicies` reports `NAMESPACED false` while `policies` reports `true` — that single column is the entire scoping story.

Because they are two distinct resource types rather than one type with a flag, they are also two distinct queries. A `Policy` will never turn up in a `ClusterPolicy` listing, which is worth seeing directly before you go looking for a policy that seems to have vanished.

> [!TIP]
> **Try it — query the two scopes separately**
>
> ```sh
> kubectl get clusterpolicy
> kubectl get policy --all-namespaces
> ```
>
> Expect something like:
>
> ```text
> Warning: kyverno.io/v1 ClusterPolicy is deprecated and will be removed in a future release; migrate to ValidatingPolicy, MutatingPolicy, GeneratingPolicy or ImageValidatingPolicy (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
> No resources found
> Warning: kyverno.io/v1 Policy is deprecated and will be removed in a future release; migrate to NamespacedValidatingPolicy and the other namespaced policy types (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
> No resources found
> ```
>
> Both are empty on a fresh playground — nothing is pre-created. The point is that these are two separate queries against two separate resource types: a `Policy` in `catalog` will never appear in the first listing, and no amount of `match` configuration will make it apply to `sandbox`.
>
> The two `Warning:` lines are expected — see the note below. They come from the API server, not from a mistake on your side, and they appear on every `kubectl` command that touches these two kinds.

> [!IMPORTANT]
> **About that deprecation warning**
>
> This playground runs Kyverno v1.19.1, and from v1.19 onwards Kyverno prints a deprecation warning whenever you read or write a `kyverno.io/v1` `ClusterPolicy` or `Policy`:
>
> ```text
> Warning: kyverno.io/v1 ClusterPolicy is deprecated and will be removed in a future release; migrate to ValidatingPolicy, MutatingPolicy, GeneratingPolicy or ImageValidatingPolicy (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
> ```
>
> Three things to take from it, in order of what matters to you right now:
>
> 1. **Nothing is broken.** A warning is not an error. The policy is still accepted, still stored, still enforced by the admission controller exactly as this course describes. v1.19 is the last release with *full* support for the legacy kinds, so everything you do here works end to end.
> 2. **This course deliberately stays on `ClusterPolicy` and `Policy`.** The KCA exam and its published curriculum are written against these kinds, so that is what you will be examined on. Learning the deprecated-but-examined API is the correct trade-off while the exam papers say so.
> 3. **The replacement is the CEL-based policy family.** Kyverno is moving toward `ValidatingPolicy`, `MutatingPolicy`, `GeneratingPolicy` and `ImageValidatingPolicy` in the `policies.kyverno.io` group (and `NamespacedValidatingPolicy` and friends for the namespaced equivalents), which express rules in CEL rather than the JMESPath-flavoured YAML you are about to learn. Same job, different syntax. When the exam moves, that is where it will move to — the [migration guide](https://kyverno.io/docs/guides/migration-to-cel/) is the map.
>
> You will see these warnings throughout every module and every lab in this series. They are noise, not signal. Read them once here and then ignore them.

## Anatomy of `spec.rules`

Every policy — `ClusterPolicy` or `Policy` — declares a list of rules under `spec.rules`. Each entry in that list is independently evaluated, and each one is built from three parts:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-team-label
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "A 'team' label is required on every Pod."
        pattern:
          metadata:
            labels:
              team: "?*"
```

Reading this top to bottom:

- `match` says which resources this rule is even allowed to consider — here, any `Pod`.
- The rule's single action block — here, `validate` — is what the rule actually *does* to matching resources.
- `validationFailureAction: Enforce` (set at the policy level, applying to every rule that doesn't override it) means a resource that fails this rule's `validate` block is rejected outright, not just logged.
- `background: true` additionally makes Kyverno periodically re-scan resources that already exist against this rule, independent of admission control — you'll use this in Module 2.

### Audit reports, Enforce blocks

`validationFailureAction` is the switch that decides what a failing `validate` rule actually costs. `Enforce` rejects the admission request outright — the user sees an error and the resource is never created. `Audit` lets the request through and records the failure instead, as an entry in a `PolicyReport`.

The practical consequence is that `Audit` is how you find out what a policy *would* break before it breaks anything, which is why a careful rollout starts there. The reporting machinery it writes into exists on the cluster from the moment Kyverno is installed, waiting for something to report.

> [!TIP]
> **Try it — look at the reporting surface**
>
> ```sh
> kubectl get policyreport --all-namespaces
> kubectl get clusterpolicyreport
> ```
>
> Expect something like:
>
> ```text
> No resources found
> No resources found
> ```
>
> Empty, because no policy exists yet to produce results. Once you apply an `Audit`-mode policy, re-running these two commands is how you read what it found — the violating resources stay in the cluster, and the verdict shows up here instead of as an admission error.

## One action per rule

A single rule commits to exactly one of four possible actions:

- **`validate`** — accept or reject a resource based on whether it matches a pattern or fails a set of conditions.
- **`mutate`** — rewrite a resource before it is persisted (add a label, inject a default, patch a field).
- **`generate`** — create a brand-new, separate resource in response to a trigger resource being created.
- **`verifyImages`** — verify container image signatures and attestations (covered in Section 040).

You cannot combine two of these in one rule. If you need a resource both mutated and then validated, you write two rules — a `mutate` rule and a `validate` rule — inside the same policy (or across two policies). Kyverno's admission flow runs all mutating rules across all policies before any validating rules, so a mutate rule can supply a missing default that a later validate rule then accepts.

> [!WARNING]
> **Common pitfalls**
>
> - **Combining two action blocks in one rule.** Putting both a `validate:` and a `mutate:` block under the same `- name:` rule entry is not just discouraged — it is invalid against Kyverno's schema, and the policy will fail to apply (or fail Kyverno's own policy validation) with an error naming the conflicting keys. Split into separate rules instead.
> - **Expecting a `Policy` to reach outside its own namespace.** A `Policy` in `catalog` cannot govern `sandbox`, no matter what its `match.resources.namespaces` says. If a rule needs to span namespaces, it has to be a `ClusterPolicy`.
> - **Treating `Audit` as "policy disabled".** An `Audit` policy is fully evaluated on every matching admission request; it just records the result rather than rejecting. It is reporting, not an off switch.

> *A Kyverno policy is a Kubernetes object first and a policy second — which is why `kubectl` is the only tool you need to find one, read its schema, and see how far its authority reaches.*

## Reference

- `kubectl explain clusterpolicy.spec` — the live schema for the API version installed on your cluster.
- Kyverno policy types documentation for the full list of supported CRDs beyond `ClusterPolicy`/`Policy`.
