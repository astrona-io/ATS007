# Part 1 — Pattern Validation & Deny Conditions

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — foreach & Background Scans](./course-02-foreach-and-background-scans.md).

This part covers the two ways a `validate` rule can express a check on fields it knows the names of: `pattern` for shape, and `deny.conditions` for boolean logic across independent fields. Part 2 adds the third — iterating a list whose length you don't know.

## Three mechanisms, one rule type

Everything in this module lives under a single rule's `validate` block. `pattern` is the declarative shape check. `deny` carries `conditions` for boolean logic across independent fields. `foreach` wraps either of those and applies it per element of a list.

Seeing them as siblings under one field is worth a moment, because it clarifies that you are not choosing between three rule *types* — you are choosing how one `validate` rule expresses its check. The API server can list the options for you.

> [!TIP]
> **Try it — list what a validate block accepts**
>
> ```sh
> kubectl explain clusterpolicy.spec.rules.validate
> ```
>
> Expect something like:
>
> ```text
> KIND:       ClusterPolicy
> VERSION:    kyverno.io/v1
>
> FIELDS:
>   deny          <Object>
>   foreach       <[]Object>
>   message       <string>
>   pattern       <>
>   ...
> ```
>
> The exact field set varies by Kyverno version, and newer versions add more. The three this module teaches — `pattern`, `deny`, `foreach` — are all peers inside the same `validate` block.

## Pattern validation

A `validate.pattern` block mirrors the shape of the resource it's checking, and Kyverno recursively compares the incoming resource against it field by field. Where a plain value like `"prod"` requires an exact match, Kyverno's pattern language layers on a small set of operators and wildcards for everything else:

| Syntax | Meaning |
| --- | --- |
| `"*"` | Matches any value, including an empty one |
| `"?*"` | Matches any non-empty value (at least one character) |
| `"?"` | Matches exactly one character |
| `">5"`, `">=5"`, `"<5"`, `"<=5"` | Numeric comparison operators |
| `"!prod"` | "Not equal to" — matches anything except `prod` |
| `"prod \| staging"` | OR between literal values |

```yaml
validate:
  message: "Deployments must run at least 2 replicas and set an 'app' label."
  pattern:
    metadata:
      labels:
        app: "?*"
    spec:
      replicas: ">=2"
```

This single pattern block checks two unrelated fields (`metadata.labels.app` and `spec.replicas`) at once, because pattern trees are ANDed together implicitly by their nested structure — every leaf in the pattern must be satisfied.

> [!TIP]
> **Try it — a rejection you can read**
>
> Apply a `ClusterPolicy` using the pattern above, then:
>
> ```sh
> kubectl create deployment too-small --image=nginx:alpine --replicas=1
> ```
>
> Expect an admission error naming your rule and quoting your `message`, with the exact field path (`/spec/replicas`) that failed — Kyverno always tells you which part of the pattern tripped. Clean up afterwards with `kubectl delete deployment too-small --ignore-not-found`.

## When a pattern isn't enough: `deny` and `conditions`

Patterns are excellent at describing *shape*, but they can't express boolean logic across independent fields — "field A equals X AND field B does not equal Y," or "field A is in this list OR field B is in that other list." For that, a validate rule uses `deny` with a `conditions` block instead of `pattern`:

```yaml
validate:
  message: "The default ServiceAccount may not be used outside kube-system."
  deny:
    conditions:
      all:
      - key: "{{ request.object.spec.serviceAccountName }}"
        operator: Equals
        value: "default"
      - key: "{{ request.object.metadata.namespace }}"
        operator: NotEquals
        value: "kube-system"
```

`conditions.all` is an AND — every listed condition must be true for the rule to deny the resource. `conditions.any` is an OR — the rule denies as soon as one condition is true. `key`/`value` pairs are compared with operators like `Equals`, `NotEquals`, `In`, and `AnyIn`; the `{{ }}` syntax pulls a live value out of the incoming request using a JMESPath-style expression (you'll see more of this in Section 020).

> [!WARNING]
> **Common pitfall**
>
> Reaching for `deny.conditions` for a check that a plain `pattern` could express just as well makes the policy harder to read for no benefit. Reserve `deny` for genuine cross-field boolean logic; use `pattern` for straightforward shape checks.

> *`pattern` describes what a resource should look like; `deny.conditions` describes what combination of facts should be refused — reach for the second only when the first cannot say it.*

## Reference

- Kyverno validate rule documentation — the complete operator and wildcard reference for `pattern`.
- `kubectl explain clusterpolicy.spec.rules.validate` — the live schema on your installed version.
