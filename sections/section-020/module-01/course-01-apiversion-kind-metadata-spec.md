# apiVersion, kind, metadata & spec

Astronaut, every Kubernetes object you have written, a Pod, a Deployment, a Service, has the same four-block shape: `apiVersion`, `kind`, `metadata` and `spec`. A Kyverno policy has that shape too, because a Kyverno policy *is* a Kubernetes object. Kyverno's installation registers it with the cluster as a Custom Resource Definition (CRD): a new kind of object that the API server stores and serves like a built-in one. There is no separate policy language, no `.rego` file and no compiler, just YAML the API server already knows how to store and serve.

<!-- astrona:playground:renew -->

Here is a complete policy, so you can see all four blocks at once. Save this as `require-team-label.yaml` and keep the file; you do not apply it in this part:

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

`apiVersion: kyverno.io/v1` tells the API server which schema to check this document against. `kind` then picks one of the two shapes that schema defines:

- **`ClusterPolicy`**: cluster-wide, a rule book for the whole solar system. It has no `metadata.namespace`, and its rules can `match` objects in any namespace, or be narrowed with a `namespaces` list inside `match`.
- **`Policy`**: namespaced, exactly like a Deployment, a planet's own rule book. It lives inside one namespace (`metadata.namespace: storefront`), and its rules only ever see objects created in that same namespace, whatever the `match` block says.

Both kinds share the same `spec` underneath: rules, `validationFailureAction`, `background` and the rest mean the same thing in either. Only the scope differs. A `ClusterPolicy` is the cluster administrator's tool for a rule that applies everywhere. A `Policy` is what you give a team that owns one namespace and should not be able to affect anyone else's.

### See both kinds registered in your playground

List the Kyverno CRDs on the cluster:

```sh
kubectl get crd | grep kyverno.io
```

You should see something like:

```text
clusterpolicies.kyverno.io                           2024-01-01T00:00:00Z
policies.kyverno.io                                  2024-01-01T00:00:00Z
policyexceptions.kyverno.io                          2024-01-01T00:00:00Z
...
```

The exact list and the timestamps depend on the Kyverno release. Both `clusterpolicies` and `policies` appear because installing Kyverno registered both kinds. That registration is what makes them ordinary objects you can query, not files some outside process reads.

## metadata: name, namespace and self-documenting annotations

`metadata.name` must be a valid DNS-1123 name: lower-case letters, numbers and hyphens, the same rule as every other Kubernetes object. For a `Policy`, `metadata.namespace` decides which namespace's objects the policy can see.

The `policies.kyverno.io/*` annotations (`title`, `category`, `description`, `subject`, `severity`) are notes in the logbook. Kyverno's decision to allow or deny an object never reads them. They exist for people and tools: `kubectl describe clusterpolicy` prints them, and reporting dashboards (such as the community Kyverno Policy Reporter) use them to group and label results.

Leaving them out changes nothing about how the policy works. But a policy with no `title` or `description` is much harder for a teammate to understand six months later without opening the YAML.

## spec: rules, and two switches that set the reach

`spec.rules` is a list. Each entry names one rule and picks exactly one action to take on a matched object: `validate`, `mutate`, `generate` or `verifyImages`. Two fields at the `spec` level, above the rules list, decide how strict the whole policy is:

- **`validationFailureAction`**: `Enforce` blocks a failing object outright (the API server returns an error and `kubectl apply` fails). `Audit` lets the object through but records the failure in a `PolicyReport`, the planet's inspection log. Teams usually roll a new policy out in `Audit` first, watch the reports for false alarms, then switch it to `Enforce`.
- **`background`**: when `true`, Kyverno also re-checks objects that already exist in the cluster, not just new ones, and records the results as `PolicyReport` or `ClusterPolicyReport` entries. This is how you find out that 40 Pods created *before* the policy existed already break it.

You do not have to take this field list on trust. The CRD carries a schema, so the API server can describe `spec` on request, the same way `kubectl explain deployment.spec` works. If `kubectl explain` can walk a policy's fields, those fields really are part of the cluster's API.

### Read the policy schema in your playground

Ask the API server to describe a policy's `spec`:

```sh
kubectl explain clusterpolicy.spec
```

You should see something like:

```text
KIND:       ClusterPolicy
VERSION:    kyverno.io/v1

FIELD: spec <Object>

DESCRIPTION:
    Spec declares policy behaviors.

FIELDS:
  background    <boolean>
  rules         <[]Object>
  ...
```

The exact field list depends on the Kyverno version. Run it again with `policy` instead of `clusterpolicy` and you get the same `spec` fields. That proves the two kinds share one schema and only differ in whether `metadata.namespace` means anything.

## Common pitfalls

> [!WARNING]
> - **Indenting `pattern` one level off.** The `validate.pattern` block must copy the shape of the real object exactly, starting from the object's own root. Leaving out the `metadata:` wrapper, like this:
>   ```yaml
>   validate:
>     pattern:
>       labels:
>         team: "?*"
>   ```
>   does not cause an error when you apply the policy. No Pod has a top-level `labels` field outside `metadata`, so the rule compares the wrong place in every Pod and does not check what you meant. The policy still shows as ready. Always check the pattern's nesting against `kubectl explain <kind>` or a real object's YAML, not against what feels natural to type.
> - **Writing `kind: Policy` without `metadata.namespace`.** A `Policy` is namespaced. Applied without a namespace, it lands in your current default namespace (often `default`) and governs nothing you care about. Set `metadata.namespace`, or pass `-n <namespace>` to `kubectl apply`.

> *`apiVersion` and `kind` pick the schema, `metadata` names and documents the policy, `spec.rules` does the work, and `validationFailureAction` and `background` decide how strictly and how far back that work reaches.*
