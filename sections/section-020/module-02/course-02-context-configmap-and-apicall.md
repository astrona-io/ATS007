# Part 2 — Context: configMap & apiCall

> Prerequisite: [Part 1 — Variables & JMESPath Basics](./course-01-variables-and-jmespath-basics.md). Next: [Landing page](./course.md).

`request.object` only ever tells you about the one resource currently being admitted. The moment a rule needs to know something *else* — a list of values a platform team maintains separately, or a fact about a different object already in the cluster — that data has to be pulled in explicitly with a `context` entry before a variable can reference it.

## context[].configMap: reading external, editable data

```yaml
context:
  - name: allowed-envs
    configMap:
      name: allowed-environments
      namespace: platform-config
```

This loads the entire ConfigMap named `allowed-environments` (from the `platform-config` namespace) into a variable named `allowed-envs`, addressable in expressions as `allowed-envs.data.<key>`. The value is whatever string is stored under that key in the ConfigMap's `data` map.

The point of `configMap` context is that the *list* changes without touching the policy at all: updating the ConfigMap (`kubectl apply -f allowed-environments.yaml`) takes effect on the next admission request, no policy edit, no `kubectl apply` on the `ClusterPolicy` itself, no downtime. This is the standard way to let a platform team own "the list of allowed values" separately from "the rule that enforces it."

The important word is *evaluation time*: the lookup happens on every request the rule matches, not once when the policy is applied. Nothing about the referenced object is Kyverno-specific — it is an ordinary ConfigMap you can read right now.

> [!TIP]
> **Try it — read the external data a context entry would pull**
>
> ```sh
> kubectl get configmap deploy-settings -n tenant-blue -o yaml
> ```
>
> Expect something like:
>
> ```text
> apiVersion: v1
> data:
>   allowed-regions: eu-north-1,eu-west-1
>   max-replicas: "5"
> kind: ConfigMap
> metadata:
>   name: deploy-settings
>   namespace: tenant-blue
> ...
> ```
>
> A `context[].configMap` entry naming this object makes `allowed-regions` and `max-replicas` readable from inside a rule as `<context-name>.data.<key>`, and a `kubectl edit` on it is enough to change what that rule permits.

## context[].apiCall: asking the API server (or another URL) a question

```yaml
context:
  - name: nsLabels
    apiCall:
      urlPath: "/api/v1/namespaces/{{ request.namespace }}"
      jmesPath: "metadata.labels"
```

`apiCall` issues an HTTP request — by default to the Kubernetes API server itself, using Kyverno's own service account credentials, though `apiCall` can also target an arbitrary external URL — and binds the (optionally JMESPath-reduced) JSON response to the named variable. The example above fetches the labels of the Namespace the incoming resource is being created in, letting a rule check something like "does this Namespace have a `cost-center` label" without that information being anywhere in the resource being admitted.

`apiCall` is strictly more expensive per-request than `configMap` (a real HTTP round trip on every admission, vs. an in-memory lookup Kyverno keeps synced via a watch), so reach for `configMap` whenever the data you need is a static or slow-changing list, and reserve `apiCall` for genuinely dynamic, request-specific lookups.

That introduces a case worth meeting deliberately: the lookup that finds nothing. The playground carries two namespaces for exactly this contrast — one labelled, one bare.

> [!TIP]
> **Try it — compare a lookup that finds data with one that does not**
>
> ```sh
> kubectl get namespace tenant-blue tenant-green --show-labels
> ```
>
> Expect something like:
>
> ```text
> NAME           STATUS   AGE   LABELS
> tenant-blue    Active   4m    cost-center=cc-4417,kubernetes.io/metadata.name=tenant-blue,tier=internal
> tenant-green   Active   4m    kubernetes.io/metadata.name=tenant-green
> ```
>
> Ages vary, and `kubernetes.io/metadata.name` is added automatically by Kubernetes on every namespace. An `apiCall` reading `cost-center` gets `cc-4417` in `tenant-blue` and *nothing* in `tenant-green` — and "nothing" is the case that quietly changes how a rule behaves.

### What a context lookup is allowed to see

An `apiCall` is not executed with your credentials. It runs as Kyverno's own service account, so it can only read what Kyverno's RBAC grants. This catches people out constantly: an expression that works perfectly when they test the equivalent `kubectl get` themselves returns empty inside the policy, because Kyverno was never given read access to that resource kind.

> [!TIP]
> **Try it — see the permission ceiling a context lookup runs under**
>
> ```sh
> kubectl get clusterrole | grep kyverno
> ```
>
> Expect something like:
>
> ```text
> kyverno:admission-controller             2024-01-01T00:00:00Z
> kyverno:admission-controller:core        2024-01-01T00:00:00Z
> kyverno:background-controller            2024-01-01T00:00:00Z
> kyverno:background-controller:core       2024-01-01T00:00:00Z
> kyverno:reports-controller               2024-01-01T00:00:00Z
> ...
> ```
>
> The exact set depends on the Kyverno version and install method. These roles — not your own — define what an `apiCall` can reach. When a lookup mysteriously returns nothing for a resource kind you can read yourself, this is the first place to check.

## preconditions: deciding whether the rule runs at all

```yaml
preconditions:
  all:
    - key: "{{ request.operation }}"
      operator: Equals
      value: CREATE
```

`preconditions` (an `any`/`all` block of conditions, using the same operator set as a `deny.conditions` block) is evaluated *before* the rule's main body (`validate`/`mutate`/`generate`). If it evaluates to false, the rule is skipped entirely for this request — no violation, no report entry, nothing — as opposed to `validate.pattern` failing, which produces an actual denial or audit finding. This distinction matters: use `preconditions` to say "this rule doesn't apply here" (e.g. skip mutation rules on `DELETE`, since there is nothing left to mutate), and use `validate` to say "this rule applies, and the resource fails it."

> [!TIP]
> **Try it — a configMap-backed allow-list with the offending value named**
>
> ```sh
> kubectl create namespace releases --dry-run=client -o yaml | kubectl apply -f -
> kubectl create configmap allowed-environments -n releases \
>   --from-literal=values=dev,staging,prod
> kubectl apply -f - <<'EOF'
> apiVersion: kyverno.io/v1
> kind: Policy
> metadata:
>   name: check-env-label
>   namespace: releases
> spec:
>   validationFailureAction: Enforce
>   rules:
>     - name: env-must-be-allowed
>       match:
>         any:
>           - resources:
>               kinds: [Pod]
>       context:
>         - name: allowed
>           configMap:
>             name: allowed-environments
>             namespace: releases
>       validate:
>         message: "env label '{{ request.object.metadata.labels.env }}' is not one of the allowed values: {{ allowed.data.values }}"
>         deny:
>           conditions:
>             all:
>               - key: "{{ request.object.metadata.labels.env }}"
>                 operator: AnyNotIn
>                 value: "{{ split(allowed.data.values, ',') }}"
> EOF
> kubectl run bad-env --image=nginx -n releases --labels=env=qa --restart=Never
> ```
>
> Expect something like:
>
> ```text
> Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
>
> check-env-label:
>   env-must-be-allowed: 'validation error: env label ''qa'' is not one of the allowed values: dev,staging,prod. rule env-must-be-allowed failed...'
> ```
>
> Both the offending value and the full allowed list came from variables — the ConfigMap, not the policy YAML, is the source of truth for what counts as "allowed."

> [!WARNING]
> **Common pitfalls**
>
> - **Forgetting a `context` entry's `name` must be unique per rule.** Two `context` entries in the same rule sharing a `name` silently means the second one overwrites the first wherever it is referenced — Kyverno does not error on the duplicate. If a variable seems to be resolving to the wrong data source, check for a name collision in that rule's `context` list before assuming the lookup itself is wrong.
> - **Assuming `context` data is read once.** It is fetched on every matching request. That is what makes a ConfigMap-backed allow-list editable without touching the policy, but it also means a deleted or renamed ConfigMap breaks the rule immediately and everywhere.
> - **Forgetting that `apiCall` runs as Kyverno.** Testing the lookup with `kubectl` proves *you* can read it, not that Kyverno can. Permission gaps surface as empty results rather than as errors.
> - **Confusing `preconditions` with `deny.conditions`.** `preconditions` decide whether the rule runs at all; `deny.conditions` decide whether a request that the rule *did* run against is rejected. Putting rejection logic in `preconditions` produces a rule that simply skips instead of blocking.

*`configMap` context reads slow-changing external data with no per-request cost beyond a lookup; `apiCall` context asks a live question at evaluation time; `preconditions` decide whether any of this runs at all for a given request.*

## Reference

- [Kyverno external data sources docs](https://kyverno.io/docs/writing-policies/external-data-sources/) — the full `context` reference, including `globalReference` and `variable` entries not covered here.
- [Kyverno preconditions docs](https://kyverno.io/docs/writing-policies/preconditions/) — the complete condition operator list shared with `deny.conditions`.
