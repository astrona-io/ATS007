# Match, Exclude & Resource Selection

Astronaut, a rule's action block (`validate`, `mutate`, `generate` or `verifyImages`) decides *what happens*. The `match` block decides *whether it happens at all* for a given object. Getting `match`, and its partner `exclude`, right is the difference between a policy that hits its target and one that misses it, or worse, blocks something it should never touch.

## The `match` block

`match` picks the ships the inspector looks at. It selects objects with one or more of these filters:

- **`resources.kinds`**: a list of Kubernetes kinds the rule looks at, for example `[Pod]` or `[Deployment, StatefulSet]`.
- **`resources.namespaces`**: only objects in these namespaces. Wildcards work, for example `dev-*`.
- **`resources.selector`**: a standard Kubernetes label selector. Only objects with matching labels (the markings painted on a ship's hull) are looked at.
- **`resources.names`**: only objects with these names. Wildcards work here too.
- **`subjects`**: select by *who* sends the request (a user, a group or a service account), not by the object itself.

Here is a `match` block that uses three filters at once:

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

This rule only looks at `Pod` objects, only in the `payments` namespace, and only when the Pod has the label `tier: backend`. Inside one `resources` entry, all filters must be true together (AND). If you list several `resources` entries under `any`, an object only needs to fit one of them (OR).

## Check the labels before you select on them

A label selector that matches nothing is the quietest failure in Kyverno. There is no error, no event and no warning. The rule simply never fires, and the policy looks installed and healthy the whole time. So before you write a `selector`, check which labels the objects you want to cover really carry.

<!-- astrona:playground:renew -->

### See the namespace labels in your playground

Your playground's three namespaces make this concrete. Show their labels:

```sh
kubectl get namespaces payments catalog sandbox --show-labels
```

You should see something like:

```text
NAME       STATUS   AGE   LABELS
payments   Active   4m    env=production,kubernetes.io/metadata.name=payments
catalog    Active   4m    env=staging,kubernetes.io/metadata.name=catalog
sandbox    Active   4m    kubernetes.io/metadata.name=sandbox
```

The ages and the built-in labels will differ on your cluster. `sandbox` has no `env` label at all. So a rule that selects `env=production` covers exactly one of these three namespaces. A typo such as `env=Production` would cover none of them, and nothing would complain.

### Read back what an applied policy is watching

The other direction is just as useful when a policy behaves strangely: ask the cluster what an applied rule is scoped to, without opening the original YAML file.

```sh
kubectl get clusterpolicy require-team-label -o jsonpath='{.spec.rules[0].match}'
```

This prints the `match` block of the first rule of that policy as JSON. It only works once a policy with that name exists. On a fresh playground it reports `NotFound`, which is a good reminder that nothing is created for you.

## The `exclude` block

`exclude` has exactly the same shape as `match`, but it takes objects away instead of adding them. It is the list of ships the inspector waves past. An object must fit `match` *and not* fit `exclude` for the rule to apply to it.

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

This is the standard shape for any broad policy: match everything of one kind, then carve out the system namespaces that should never be checked. The most important one is `kyverno` itself.

Why does that matter? A `ClusterPolicy` that matches every Pod, with no exclusion for the `kyverno` namespace, can block Kyverno's own admission controller Pods the next time they restart. The inspector would lock itself out of the launch gate. One `exclude` block prevents that outage.

## Common pitfalls

> [!WARNING]
> - **Forgetting to exclude `kyverno` (and usually `kube-system`) from a broad `ClusterPolicy`.** A rule that matches "every Pod" really means every Pod, including Kyverno's own.
> - **Excluding the namespace you are testing in.** If `exclude` is too broad, every test object you create is silently skipped, and the policy looks like it enforces nothing.
> - **Reading `exclude` as an off switch.** `exclude` narrows what `match` selected. The rule still applies to everything `match` selected and `exclude` did not take away.
> - **Thinking a silent rule means a broken install.** A `match` block that selects nothing (a mistyped label value, a kind that does not exist) gives no error and no events. Check that the selection matches real objects before you suspect Kyverno.
> - **Adding a namespace filter to a `Policy`.** A `Policy` is already limited to its own namespace. A namespace filter inside it adds nothing (it does no harm if it names that same namespace).

> *`match` selects and `exclude` takes away, and because a selection that matches nothing fails silently, checking the labels first is how you find out the rule works at all.*

## Your mission: ClusterPolicy Label Enforcement

You can now read a policy's rules and scope them with `match` and `exclude`. The mission asks you to write a `ClusterPolicy` that requires a `team` label on Pods in one namespace, keep a system namespace out of it, and prove it blocks one Pod and admits another.

The mission runs in its own training solar system, so first pause your playground. Nothing in it is lost:

```sh
astrona stop section-010-module-01-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-01/labs/lab-01
```

Read the task in [question.md](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-007-lab-001
astrona start section-010-module-01-playground
```
