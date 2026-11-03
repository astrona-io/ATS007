# Pattern Validation & Deny Conditions

Astronaut, this part covers the two ways a `validate` rule can check fields whose names you know in advance. `pattern` checks the *shape* of an object. `deny.conditions` checks *logic* across fields that have nothing to do with each other.

## Three tools, one rule type

Everything in this module lives under one rule's `validate` block. `pattern` is the shape check: a stencil the ship must fit. `deny` holds `conditions`: a list of "no launch if ..." checks. `foreach` wraps either of those and applies it to every item of a list.

They are options side by side under one field. You are not choosing between three rule *types*; you are choosing how one `validate` rule expresses its check.

<!-- astrona:playground:renew -->

### See the options in your playground

The API server can list what a `validate` block accepts:

```sh
kubectl explain clusterpolicy.spec.rules.validate
```

You should see something like:

```text
KIND:       ClusterPolicy
VERSION:    kyverno.io/v1

FIELDS:
  deny          <Object>
  foreach       <[]Object>
  message       <string>
  pattern       <>
  ...
```

The exact field set changes between Kyverno versions, and newer versions add more. The three this module teaches, `pattern`, `deny` and `foreach`, all sit side by side inside the same `validate` block.

## Pattern validation

A `validate.pattern` block copies the shape of the object it checks. Kyverno walks through the incoming object and compares it with the pattern, field by field. A plain value such as `"prod"` must match exactly. For everything else, Kyverno's pattern language adds a few operators and wildcards:

| Syntax | Meaning |
| --- | --- |
| `"*"` | Matches any value, including an empty one |
| `"?*"` | Matches any non-empty value (at least one character) |
| `"?"` | Matches exactly one character |
| `">5"`, `">=5"`, `"<5"`, `"<=5"` | Number comparisons |
| `"!prod"` | "Not equal to": matches anything except `prod` |
| `"prod \| staging"` | OR between plain values |

Here is a pattern that checks two fields at once:

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

This one pattern checks two unrelated fields, `metadata.labels.app` and `spec.replicas`. Every leaf in a pattern must be satisfied, so the checks are ANDed together by the nested structure itself.

### See a rejection in your playground

Put that pattern into a real policy and watch it reject a Deployment. To keep it away from the system namespaces, this policy only matches Deployments in `default`.

Save this as `clusterpolicy-require-replicas-and-app-label.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-replicas-and-app-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-replicas-and-app-label
      match:
        any:
        - resources:
            kinds:
              - Deployment
            namespaces:
              - default
      validate:
        message: "Deployments must run at least 2 replicas and set an 'app' label."
        pattern:
          metadata:
            labels:
              app: "?*"
          spec:
            replicas: ">=2"
```

Apply it:

```sh
kubectl apply -f clusterpolicy-require-replicas-and-app-label.yaml
```

Then try to create a Deployment with only one replica:

```sh
kubectl create deployment too-small --image=nginx:alpine --replicas=1
```

Look for an admission error that names your rule, quotes your `message`, and gives the exact field path that failed (`/spec/replicas`). Kyverno always tells you which part of the pattern tripped. `kubectl create deployment` sets the `app` label for you, so only the replica count fails.

Clean up afterwards, so the policy does not get in the way later:

```sh
kubectl delete deployment too-small --ignore-not-found
kubectl delete clusterpolicy require-replicas-and-app-label
```

## When a pattern is not enough: `deny` and `conditions`

Patterns are very good at describing *shape*. They cannot express true-or-false logic across separate fields, such as "field A equals X AND field B does not equal Y". For that, a validate rule uses `deny` with a `conditions` block instead of `pattern`:

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

`conditions.all` is an AND: every listed condition must be true before the rule denies the object. `conditions.any` is an OR: the rule denies as soon as one condition is true. Each `key` is compared with its `value` using an operator such as `Equals`, `NotEquals`, `In` or `AnyIn`.

The `{{ }}` marks a variable: a blank in the rule that Kyverno fills from the launch request. The text inside is a JMESPath expression, the way the inspector reads one line off a form. Here `request.object.spec.serviceAccountName` reads the service account name from the incoming Pod.

## Common pitfalls

> [!WARNING]
> - **Using `deny.conditions` for a plain shape check.** If a `pattern` can say it, use the `pattern`. `deny` makes the policy harder to read and should be kept for real logic across fields.
> - **Using `"*"` when you mean "must be set".** `"*"` also matches an empty value. Use `"?*"` when the field must have at least one character.
> - **Mixing up `all` and `any`.** `all` denies only when every condition is true; `any` denies when one is. Swapping them makes a rule far stricter or far looser than you meant.
> - **Leaving a test policy behind.** An `Enforce` policy you applied to experiment keeps blocking objects. Delete it when you are done.

> *`pattern` describes what an object should look like; `deny.conditions` describes which combination of facts should be refused, so reach for the second only when the first cannot say it.*
