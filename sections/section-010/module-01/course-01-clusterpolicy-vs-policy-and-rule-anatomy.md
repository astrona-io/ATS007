# ClusterPolicy vs Policy & Rule Anatomy

Astronaut, before you write a rule book, you need to know what a rule book looks like. This part shows what a Kyverno policy *is* as an object, which of the two policy kinds to pick, and how the list of rules inside a policy is built.

## Policies are Kubernetes resources

When Kyverno is installed, it adds new object types to the cluster. Kubernetes calls them Custom Resource Definitions (CRDs): new kinds of object that the API server (mission control) stores and serves like any built-in kind. The two most important ones are `ClusterPolicy` and `Policy`.

Both are ordinary Kubernetes objects. They are stored in etcd (mission control's archive), they show up in `kubectl get`, and Kyverno's own controllers watch them. When you apply a policy, those controllers turn it into live checks on every matching request.

That has three useful results. A Kyverno policy can be:

- Reviewed in a pull request, next to the workload files it governs.
- Applied with the tools you already use for everything else (`kubectl`, Helm, Argo CD, Flux).
- Read by anyone who knows YAML and Kubernetes objects. There is no Rego, no Cedar and no separate expression language to learn.

There is one more benefit. The API server holds the schema for these new kinds, so you do not need special Kyverno tools to find out what a rule may contain. `kubectl explain` reads the same schema the API server checks against.

<!-- astrona:playground:renew -->

### See the rule schema in your playground

Ask the cluster which fields a rule may have:

```sh
kubectl explain clusterpolicy.spec.rules --recursive | head -20
```

You should see something like:

```text
GROUP:      kyverno.io
KIND:       ClusterPolicy
FIELDS:
  match     <Object>
  exclude   <Object>
  validate  <Object>
  mutate    <Object>
  ...
```

The exact field list and order change between Kyverno versions. What matters is that the cluster itself can tell you the rule schema. When you are not sure a field exists on your version, this command gives the real answer.

## ClusterPolicy vs Policy

Kyverno gives you two kinds of policy object. The only difference between them is scope: how far their authority reaches.

| Kind | Scope | Typical use |
| --- | --- | --- |
| `ClusterPolicy` | Cluster-wide. Its rules can match objects in any namespace, and cluster-scoped objects, unless you narrow them | Guardrails for the whole organisation: "every Pod everywhere must set resource limits" |
| `Policy` | Namespaced. It lives inside one namespace, and its rules can only match objects in that same namespace | Rules a team or tenant controls for its own namespace |

In space terms, a `ClusterPolicy` is a rule book for the whole solar system. A `Policy` is one planet's own rule book: it can only cover ships on that planet.

Both kinds share the exact same `spec` underneath: the same `rules`, `match`, `exclude` and action blocks shown later in this part. Only where the object lives, and how far it reaches, is different.

### See both kinds in your playground

The scope difference is written into the API registration itself, in the `NAMESPACED` column. List the Kyverno kinds:

```sh
kubectl api-resources --api-group=kyverno.io
```

You should see something like:

```text
NAME                 SHORTNAMES   APIVERSION      NAMESPACED   KIND
cleanuppolicies      cleanpol     kyverno.io/v2   true         CleanupPolicy
clusterpolicies      cpol         kyverno.io/v1   false        ClusterPolicy
policies             pol          kyverno.io/v1   true         Policy
```

The exact list changes between Kyverno versions. `clusterpolicies` shows `NAMESPACED false` and `policies` shows `true`. That one column is the whole scoping story.

### Query the two scopes separately

They are two different object types, not one type with a switch. So they are also two different queries, and a `Policy` never turns up in a `ClusterPolicy` list. List both:

```sh
kubectl get clusterpolicy
kubectl get policy --all-namespaces
```

You should see something like:

```text
Warning: kyverno.io/v1 ClusterPolicy is deprecated and will be removed in a future release; migrate to ValidatingPolicy, MutatingPolicy, GeneratingPolicy or ImageValidatingPolicy (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
No resources found
Warning: kyverno.io/v1 Policy is deprecated and will be removed in a future release; migrate to NamespacedValidatingPolicy and the other namespaced policy types (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
No resources found
```

Both lists are empty, because nothing is created for you. A `Policy` in `catalog` would never appear in the first list, and no `match` setting can make it apply to `sandbox`.

The two `Warning:` lines are expected. The API server prints them, not because you made a mistake, and they appear on every `kubectl` command that touches these two kinds. The next section explains them.

## About the deprecation warning

Your playground runs Kyverno v1.19.1. From v1.19 on, the API server prints a deprecation warning whenever you read or write a `kyverno.io/v1` `ClusterPolicy` or `Policy`. "Deprecated" means "still works, but planned to be replaced". Take three things from the warning:

1. **Nothing is broken.** A warning is not an error. The policy is still accepted, stored and enforced by the Kyverno admission controller exactly as this course describes. v1.19 still fully supports these kinds, so everything here works end to end.
2. **This course stays on `ClusterPolicy` and `Policy` on purpose.** The KCA (Kyverno Certified Associate) exam and its curriculum are written against these kinds, so they are what you will be tested on.
3. **The replacement is a new family of policies written in CEL** (Common Expression Language, a small expression language used across Kubernetes). They are `ValidatingPolicy`, `MutatingPolicy`, `GeneratingPolicy` and `ImageValidatingPolicy` in the `policies.kyverno.io` group, plus namespaced versions such as `NamespacedValidatingPolicy`. They do the same job with a different syntax.

You will see these warnings in every module and every lab of this course. Read them once here, and then treat them as background noise.

## Anatomy of `spec.rules`

Every policy, cluster-wide or namespaced, has a list of rules under `spec.rules`. Each rule is one page of the rule book. Kyverno checks each rule on its own. Here is a complete policy to read, top to bottom. You do not need to apply it now.

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

Each line has a job:

- `match` says which objects this rule may look at: here, any `Pod`. It is the list of ships the inspector looks at.
- The rule's one action block, here `validate`, is what the rule *does* to matching objects. A `validate` rule stamps a launch request approved or rejected.
- `validationFailureAction: Enforce` is set at the policy level, so it applies to every rule that does not override it. It means an object that fails the `validate` block is rejected, not just logged.
- `background: true` also makes Kyverno re-check objects that already exist against this rule, separately from admission. Think of it as patrol inspections of ships that are already flying.

### Audit reports, Enforce blocks

`validationFailureAction` decides what a failing `validate` rule costs. With `Enforce`, Kyverno rejects the request: the user sees an error, and the object is never created. The launch is blocked. With `Audit`, Kyverno lets the request through and writes the failure down in a `PolicyReport` instead. The launch goes ahead, but it is written in the inspection log.

So `Audit` is how you find out what a policy *would* break before it breaks anything. That is why a careful rollout starts in `Audit`. The reports a policy writes into exist from the moment Kyverno is installed. Look at them now:

```sh
kubectl get policyreport --all-namespaces
kubectl get clusterpolicyreport
```

You should see something like:

```text
No resources found
No resources found
```

They are empty because no policy exists yet. A `PolicyReport` is the inspection log for one namespace; a `ClusterPolicyReport` is the log for the whole cluster. Once you apply an `Audit` policy, these two commands are how you read what it found: the failing objects stay in the cluster, and the verdict shows up here instead of as an error.

## One action per rule

A single rule commits to exactly one of four actions:

- **`validate`**: accept or reject an object, based on whether it matches a pattern or fails a set of conditions.
- **`mutate`**: change an object before it is stored (add a label, set a default, patch a field). This is the ground crew adjusting a ship before launch.
- **`generate`**: create a new, separate object when a trigger object is created. This is building a standard supply depot on every new planet.
- **`verifyImages`**: check the signatures on container images. This is checking the shipyard's seal before launch.

You cannot combine two of these in one rule. If you need an object both changed and then checked, write two rules, a `mutate` rule and a `validate` rule, in the same policy or in two policies. Kyverno runs all mutate rules from all policies before any validate rules. So a mutate rule can fill in a missing default that a validate rule then accepts.

## Common pitfalls

> [!WARNING]
> - **Putting two action blocks in one rule.** A `validate:` and a `mutate:` block under the same `- name:` entry break Kyverno's schema. The policy fails to apply, with an error naming the clashing keys. Split them into two rules.
> - **Expecting a `Policy` to reach outside its namespace.** A `Policy` in `catalog` cannot govern `sandbox`, whatever its `match.resources.namespaces` says. If a rule must span namespaces, it has to be a `ClusterPolicy`.
> - **Treating `Audit` as "policy switched off".** An `Audit` policy is fully checked on every matching request. It records the result instead of rejecting. It is reporting, not an off switch.
> - **Reading the deprecation warning as an error.** The `Warning: kyverno.io/v1 ClusterPolicy is deprecated` line comes from the API server on every command. The command still worked.

> *A Kyverno policy is a Kubernetes object first and a policy second, which is why `kubectl` is the only tool you need to find one, read its schema and see how far its authority reaches.*
