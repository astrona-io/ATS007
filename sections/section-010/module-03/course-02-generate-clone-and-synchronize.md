# Generate: Clone & Synchronize

Astronaut, mutate rules edit the object that triggered them. Sometimes what you really need is a *different, new* object to appear as a side effect: a default `NetworkPolicy` the moment a namespace is created, or a shared ConfigMap copied into every new namespace without anyone having to remember. That is what `generate` rules are for.

## Generation creates separate objects

A `generate` rule does not touch the object that triggered it. It watches for a trigger, most often a new `Namespace`, and creates a *different* object in response: a default `NetworkPolicy` (the planet's shield settings), a `ResourceQuota`, or a copy of a shared ConfigMap (a notice board with settings pinned to it). The trigger object itself is admitted unchanged.

Generation reacts to events in the cluster, not to the admission answer itself. So the Kyverno background controller does the work, not the admission controller. That is also why a generated object can appear a moment after its trigger, rather than at exactly the same time.

## Two ways to describe the new object

A generate rule can carry the new object's contents itself, or copy them from an object that already exists. Both fit inside the same `generate` block.

### Generating from an inline definition

The simplest form writes the new object's contents directly inside the policy, under `data`:

```yaml
generate:
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  name: default-deny-all
  namespace: "{{request.object.metadata.name}}"
  synchronize: true
  data:
    spec:
      podSelector: {}
      policyTypes:
        - Ingress
        - Egress
```

When the rule's `match` block selects `Namespace` objects, this creates a `NetworkPolicy` named `default-deny-all` inside each new namespace. The variable `{{request.object.metadata.name}}` is filled with the new namespace's own name when the object is generated.

### Generating with `clone`

Instead of writing the contents inline, `clone` copies an object that already lives somewhere in the cluster. It is the standard way to spread a shared Secret or ConfigMap into every namespace without keeping many hand-made copies of the same content:

```yaml
generate:
  apiVersion: v1
  kind: ConfigMap
  name: shared-settings
  namespace: "{{request.object.metadata.name}}"
  synchronize: true
  clone:
    namespace: platform
    name: shared-settings
```

Here the original is the `shared-settings` ConfigMap in the `platform` namespace. Every new namespace gets its own copy, made by Kyverno rather than by a script someone has to remember to run. Think of it as copying a standard depot from a template planet onto every new planet.

<!-- astrona:playground:renew -->

### Inspect the clone source in your playground

Your playground has a source object of exactly this kind. Look at it:

```sh
kubectl -n platform-config get configmap cluster-defaults -o yaml | head -15
```

You should see something like:

```text
apiVersion: v1
data:
  log-level: info
  region: eu-west-1
  telemetry-endpoint: otel-collector.platform-config.svc:4317
kind: ConfigMap
metadata:
  name: cluster-defaults
  namespace: platform-config
```

Three keys in one namespace. A `generate` rule with `clone` pointing at this object turns it into a copy in every namespace created from then on. The source stays where it is, and each copy is a separate object with its own life.

## `synchronize`: what stays in step, and with what

`generate.synchronize` decides what happens *after* the first copy is made:

- **`synchronize: false`**: the object is generated once. Later edits to the copy, or to the source it was cloned from, are never passed on. It is a one-time starting point.
- **`synchronize: true`**: Kyverno keeps the generated object in step with its source (for `clone`) or with the policy (for an inline `data` block). If someone edits the copy by hand, Kyverno puts it back. If the source object, or the policy itself, is deleted, the generated copies are deleted too.

Neither is always right. Synchronised generation gives you a guarantee. Unsynchronised generation gives namespace owners room to adapt what they were given.

## Common pitfalls

> [!WARNING]
> - **Setting `synchronize: true` on something owners are meant to adjust.** A generated `ResourceQuota` that some teams need bigger will have every local edit quietly put back. That is the feature working as designed. Use `synchronize: true` for rules that must never drift, and `synchronize: false` for starting points owners are expected to change.
> - **Forgetting that deleting the policy deletes synchronised copies.** With `synchronize: true`, removing the generate rule, or its source object, removes what it generated. Cleaning up a policy can remove a `NetworkPolicy` or ConfigMap that running workloads depend on.
> - **Expecting a generated object to appear at once.** The background controller reacts to the trigger event. A short gap between the trigger and the generated object is normal; wait a moment and check again.

> *A generated object is a separate object with its own life, and `synchronize` decides whether that life belongs to the policy or to whoever edits it next.*

## Your mission: Mutate & Generate Rules

You can now change incoming objects with a mutate rule and create new objects with a generate rule. The mission asks you to write two policies: one that labels every new Pod in a namespace, and one that puts a default-deny `NetworkPolicy` into every new namespace, then prove both.

The mission runs in its own training solar system, so first pause your playground. Nothing in it is lost:

```sh
astrona stop section-010-module-03-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-010/module-03/labs/lab-01
```

Read the task in [question.md](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-007-lab-003
astrona start section-010-module-03-playground
```
