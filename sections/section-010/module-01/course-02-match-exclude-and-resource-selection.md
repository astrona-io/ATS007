# Part 2 — Match, Exclude & Resource Selection

> Prerequisite: [Part 1 — ClusterPolicy vs Policy & Rule Anatomy](./course-01-clusterpolicy-vs-policy-and-rule-anatomy.md). Next: [Module 2 — Validate Rules](../module-02/course.md).

A rule's action block — `validate`, `mutate`, `generate`, or `verifyImages` — decides *what happens*. The `match` block decides *whether it happens at all* for a given resource. Getting `match` (and its counterpart, `exclude`) right is what separates a policy that behaves exactly as intended from one that either misses its target or, worse, blocks something it should never have touched.

## The `match` block

`match` selects resources using one or more of these filters:

- **`resources.kinds`** — a list of Kubernetes Kinds this rule considers, e.g. `[Pod]`, `[Deployment, StatefulSet]`.
- **`resources.namespaces`** — restrict matching to specific namespaces (glob patterns are supported, e.g. `dev-*`).
- **`resources.selector`** — a standard Kubernetes label selector; only resources carrying matching labels are considered.
- **`resources.names`** — match specific resource names (supports wildcards).
- **`subjects`** — match based on the identity (user, group, or service account) making the request, rather than the resource itself.

```yaml
match:
  any:
  - resources:
      kinds:
        - Pod
      namespaces:
        - payments
      selector:
        matchLabels:
          tier: backend
```

This rule only considers `Pod` resources, only inside the `payments` namespace, and only when that Pod carries the label `tier: backend`. All three conditions apply together (they are ANDed) inside a single `resources` entry; wrapping multiple `resources` entries in `any` lets you OR separate match conditions together.

### Confirm the labels before you select on them

A label selector that matches nothing is the quietest failure in Kyverno. There is no error, no event, and no warning — the rule simply never fires, and the policy looks installed and healthy the whole time. So before writing a `selector`, it is worth checking what labels are actually present on the resources you intend to cover.

The playground's three namespaces exist to make that concrete rather than abstract: a rule matching `env=production` covers `payments` and nothing else; one matching all namespaces covers all three.

> [!TIP]
> **Try it — check what a selector would have to match**
>
> ```sh
> kubectl get namespaces payments catalog sandbox --show-labels
> ```
>
> Expect something like:
>
> ```text
> NAME       STATUS   AGE   LABELS
> payments   Active   4m    env=production,kubernetes.io/metadata.name=payments
> catalog    Active   4m    env=staging,kubernetes.io/metadata.name=catalog
> sandbox    Active   4m    kubernetes.io/metadata.name=sandbox
> ```
>
> Ages and the exact built-in label set vary. `sandbox` carries no `env` label at all, so a rule whose `match` selects `env=production` covers exactly one of these three namespaces — and a typo like `env=Production` would cover none, without complaining.

That covers the resources going in. The other direction — reading back what an already-applied rule believes it is scoped to — is just as useful when a policy is behaving unexpectedly, and does not require re-reading the original YAML file.

> [!TIP]
> **Try it — inspect what an applied policy is watching**
>
> ```sh
> kubectl get clusterpolicy require-team-label -o jsonpath='{.spec.rules[0].match}'
> ```
>
> This returns the JSON form of the `match` block on the first rule of that policy. It only works once you have applied a policy by that name — on a fresh playground it reports `NotFound`, which is itself a useful reminder that nothing is pre-created here.

## The `exclude` block

`exclude` has the identical shape to `match`, but subtracts instead of selects. A resource must satisfy `match` *and not* satisfy `exclude` for the rule to apply to it.

```yaml
match:
  any:
  - resources:
      kinds:
        - Pod
exclude:
  any:
  - resources:
      namespaces:
        - kube-system
        - kyverno
```

This is the standard shape for any broadly-scoped policy: match everything of a kind, then explicitly carve out the system namespaces that should never be subject to it — most importantly `kyverno` itself. A `ClusterPolicy` that matches every Pod with no exclusion for the `kyverno` namespace can end up blocking Kyverno's own admission-controller Pods on their next restart, which is a self-inflicted outage that's easy to avoid with one `exclude` block.

> [!WARNING]
> **Common pitfalls**
>
> - **Forgetting to exclude `kyverno` (and usually `kube-system`) from a broad `ClusterPolicy`.** A rule that matches "every Pod" really does mean every Pod, including Kyverno's own.
> - **Excluding the very namespace you're testing in.** If your `exclude` block is too broad — say, excluding an entire label selector you also use on your test resources — your policy will look like it isn't enforcing anything, when in fact every test resource you're creating is being silently excluded.
> - **Reading `exclude` as an off switch.** `exclude` narrows a rule's existing `match` selection; it never disables the rule. A rule with an `exclude` block still applies to everything `match` selected and `exclude` did not carve out.
> - **Assuming a silent rule is a broken installation.** A `match` block that selects nothing — a mistyped label value, a `kinds` entry that does not exist — produces no error and no events. It simply never fires. Confirm the selection matches real resources before suspecting Kyverno.
> - **Assuming a `Policy` needs a `resources.namespaces` filter.** It doesn't — a `Policy` is already confined to its own namespace by virtue of where the object itself lives; adding a namespace filter inside it is redundant (though harmless if it names that same namespace).

> *`match` selects and `exclude` subtracts — and because a selection that matches nothing fails silently, checking the labels first is not optional caution, it is how you find out the rule works at all.*

## Reference

- `kubectl explain clusterpolicy.spec.rules.match` — the live schema for `match`/`exclude` filters on your installed Kyverno version.
- Kubernetes label selector syntax (`matchLabels`, `matchExpressions`) — `resources.selector` uses the same standard selector format as every other Kubernetes API object.
