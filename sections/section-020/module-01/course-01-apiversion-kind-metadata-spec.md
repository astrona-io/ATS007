# Part 1 — apiVersion, kind, metadata & spec

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Applying & Inspecting with kubectl](./course-02-applying-and-inspecting-with-kubectl.md).

Every Kubernetes object you have ever written — a Pod, a Deployment, a Service — follows the same four-block shape: `apiVersion`, `kind`, `metadata`, `spec`. A Kyverno policy follows that shape too, because a Kyverno policy *is* a Kubernetes object, defined by a Custom Resource Definition (CRD) that the Kyverno installation registers with the cluster. There is no separate policy language to learn, no `.rego` files, no compiler — just YAML the API server already knows how to store, version, and serve.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
  annotations:
    policies.kyverno.io/title: Require Team Label
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/description: >-
      Every Pod must carry a 'team' label so cost and ownership can be traced.
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

## apiVersion and kind: which object are you creating?

`apiVersion: kyverno.io/v1` tells the API server which CRD's schema to validate this document against. `kind` then picks one of two shapes that CRD defines:

- **`ClusterPolicy`** — cluster-scoped. It has no `metadata.namespace`, and its rules can `match` resources in any namespace (or be scoped down with a `namespaces` list inside `match`).
- **`Policy`** — namespaced, exactly like a Deployment. It lives inside one namespace (`metadata.namespace: storefront`), and its rules only ever see resources created in that same namespace, regardless of what the `match` block says.

Both kinds share the identical `spec` schema underneath — rules, `validationFailureAction`, `background`, and so on all mean the same thing in either. The only difference is scope: a `ClusterPolicy` is a cluster administrator's tool for a rule that should apply everywhere; a `Policy` is what you hand to a team that owns one namespace and should not be able to affect anyone else's.

> [!TIP]
> **Try it — see both kinds registered as CRDs**
>
> ```sh
> kubectl get crd | grep kyverno.io
> ```
>
> Expect something like:
>
> ```text
> clusterpolicies.kyverno.io                           2024-01-01T00:00:00Z
> policies.kyverno.io                                  2024-01-01T00:00:00Z
> policyexceptions.kyverno.io                          2024-01-01T00:00:00Z
> ...
> ```
>
> The exact list and timestamps vary with the Kyverno release. Both `clusterpolicies` and `policies` appear because installing Kyverno registered both kinds — that registration is what makes them ordinary, queryable cluster resources rather than files some external process reads.

## metadata: name, namespace, and self-documenting annotations

`metadata.name` must be a valid DNS-1123 name, same rule as every other Kubernetes object. For a `Policy`, `metadata.namespace` decides which namespace's resources this policy can see.

The `policies.kyverno.io/*` annotations (`title`, `category`, `description`, `subject`, `severity`) are not read by the admission-control logic at all — Kyverno's own decision to allow or deny a resource never looks at them. They exist purely for humans and tooling: `kubectl describe clusterpolicy` prints them, and policy-reporting dashboards (including the community Kyverno Policy Reporter) use them to group and label results. Skipping them costs you nothing functionally, but a policy with no `title`/`description` is much harder for a teammate to understand six months from now without opening the YAML.

## spec: rules, and two switches that control blast radius

`spec.rules` is a list; each entry names one rule and picks exactly one action for it to perform against a matched resource — `validate`, `mutate`, `generate`, or `verifyImages` (rule types covered in Section 010). Two fields at the `spec` level, above the rules list, control how forgiving the whole policy is:

- **`validationFailureAction`** — `Enforce` blocks a non-compliant resource outright (the API server returns an error, `kubectl apply` fails); `Audit` lets the resource through but records the failure in a `PolicyReport` for later review. Teams typically roll out a new policy in `Audit` first, watch the reports for a while to catch false positives, then flip it to `Enforce`.
- **`background`** — when `true`, Kyverno periodically re-evaluates this policy against resources that already exist in the cluster (not just ones being created right now), and records the results as `PolicyReport`/`ClusterPolicyReport` entries. This is how you find out that 40 Pods created *before* the policy existed are already non-compliant.

You do not have to take this field list on faith. Because the CRD carries an OpenAPI schema, `spec` is a typed object the API server can describe on demand — the same mechanism behind `kubectl explain deployment.spec`. If `kubectl explain` can walk a Kyverno policy's fields, those fields are genuinely part of the cluster's API surface, not a private format parsed somewhere else later.

> [!TIP]
> **Try it — read the policy schema out of the API server**
>
> ```sh
> kubectl explain clusterpolicy.spec
> ```
>
> Expect something like:
>
> ```text
> KIND:       ClusterPolicy
> VERSION:    kyverno.io/v1
>
> FIELD: spec <Object>
>
> DESCRIPTION:
>     Spec declares policy behaviors.
>
> FIELDS:
>   background    <boolean>
>   rules         <[]Object>
>   ...
> ```
>
> The exact field list depends on the Kyverno version. Swapping `clusterpolicy` for `policy` prints the same `spec` fields — the concrete proof that the two kinds share one schema and differ only in whether `metadata.namespace` is meaningful.

> [!WARNING]
> **Common pitfalls**
>
> - **Indenting `pattern` one level off.** The `validate.pattern` block must mirror the shape of the real resource exactly, starting from the resource's own root. Writing
>   ```yaml
>   validate:
>     pattern:
>       labels:
>         team: "?*"
>   ```
>   (missing the `metadata:` wrapper) does not error — it silently matches nothing, because no Pod has a top-level `labels` field outside `metadata`. The rule shows as `ready: true` and simply never fires. Always match the pattern's nesting against `kubectl explain <kind>` or a real resource's YAML, not against what feels natural to type.
> - **Writing `kind: Policy` without `metadata.namespace`.** A `Policy` is namespaced. Applied without a namespace it lands in whatever namespace your current context defaults to (often `default`), and then silently governs nothing you care about. Either set `metadata.namespace` explicitly or pass `-n <namespace>` to `kubectl apply`.

*`apiVersion`/`kind` pick the schema; `metadata` names and documents it; `spec.rules` does the work — and `validationFailureAction`/`background` decide how loudly and how far back that work reaches.*

## Reference

- `kubectl explain clusterpolicy.spec` / `kubectl explain policy.spec` — the live schema for the version of Kyverno installed on your cluster.
- [Kyverno policy structure docs](https://kyverno.io/docs/writing-policies/) — the canonical field-by-field reference this part only summarizes.
