# Mutate: patchStrategicMerge & patchesJson6902

Astronaut, Kyverno runs mutate rules before validate rules. That order is what makes mutate rules good for defaults: the ground crew fills in a missing field first, and the final inspection then accepts the now-complete ship without bothering the person who sent it.

## Mutation happens on the way in

A `mutate` rule changes an object during admission, before it is stored. The part that surprises people is the other side of this: an object admitted *before* the rule existed never passed through it, so it stays exactly as it was. Mutation does not go back over everything already in the cluster.

Your playground's `existing-api` Pod is there to make this visible. Whatever mutate rule you write, this Pod is older than it. So it is the control case to compare with any Pod you create afterwards.

<!-- astrona:playground:renew -->

### Record the "before" state

Show the labels on the existing Pod:

```sh
kubectl -n catalog get pod existing-api --show-labels
```

You should see something like:

```text
NAME           READY   STATUS    RESTARTS   AGE   LABELS
existing-api   1/1     Running   0          5m    run=existing-api
```

One label, added by `kubectl run`. When you later apply a mutate rule that adds a label to Pods in `catalog`, this command still shows this Pod unchanged, while a newly created Pod picks the label up. That contrast is the whole point of this Pod.

## Two patch styles, and why both exist

Kyverno offers two ways to describe a change. They sit side by side under the same `mutate` block.

`patchStrategicMerge` describes the shape you want and lets Kubernetes merge it in, field by field. It fits adding a label, an annotation or a default field, because you write the same nested YAML you would have written by hand.

`patchesJson6902` takes a list of exact steps, such as `add`, `replace` and `remove`, each with a `path` and a `value`. The name comes from RFC 6902, the published internet standard (Request for Comments) that defines JSON Patch. You use it when position matters, most often when editing a list by its index, which a merge cannot express.

### See the mutate fields in your playground

Ask the cluster what a `mutate` block accepts:

```sh
kubectl explain clusterpolicy.spec.rules.mutate
```

You should see something like:

```text
KIND:       ClusterPolicy
VERSION:    kyverno.io/v1

FIELDS:
  foreach                <[]Object>
  patchStrategicMerge    <>
  patchesJson6902        <string>
  targets                <[]Object>
  ...
```

The field set changes between Kyverno versions. Note `targets` next to the two patch styles. That field extends mutation to objects other than the one being admitted, which is how mutation reaches existing objects when you really need it to.

## `patchStrategicMerge`: overlay-style patching

`patchStrategicMerge` describes the change as an overlay: a piece of the target object's own shape, merged onto the incoming object. It reads almost exactly like the object it patches.

```yaml
mutate:
  patchStrategicMerge:
    metadata:
      labels:
        managed-by: kyverno
```

On any matching Pod, this merges the `managed-by: kyverno` label into `metadata.labels` and leaves every other label untouched. Strategic merge is the right tool whenever the change is "add or overwrite this field". That includes nested objects and lists that Kubernetes knows how to merge by name, for example adding an environment variable to one named container without disturbing the others.

### Watch a label appear with no manual edit

If a policy with this mutate rule is active for Pods in `catalog`, create a Pod there:

```sh
kubectl run mutate-me --image=nginx:alpine -n catalog
kubectl get pod mutate-me -n catalog --show-labels
```

Look for `managed-by=kyverno` in the labels, even though your `kubectl run` command never mentioned it. The Kyverno admission controller added it in flight, before the API server stored the object. Clean up with `kubectl delete pod mutate-me -n catalog --ignore-not-found`.

## `patchesJson6902`: exact, path-addressed patching

Some edits cannot be written as a clean overlay: inserting into the middle of a list by position, or replacing one list item without touching the others. For those, Kyverno supports JSON Patch through `patchesJson6902`:

```yaml
mutate:
  patchesJson6902: |-
    - op: add
      path: "/spec/containers/0/env/-"
      value:
        name: TRACE_ENABLED
        value: "true"
```

Each entry is one exact operation (`add`, `replace`, `remove` and so on) on one exact path. The `-` at the end of the path means "add to the end of this list". `patchStrategicMerge` says "merge this shape in"; `patchesJson6902` says "make exactly this edit, at exactly this place". It is longer to write, but it is never unclear about list positions.

## Common pitfalls

> [!WARNING]
> - **Using `patchesJson6902` by default because it feels more exact.** It makes simple label and annotation changes far longer than they need to be. Use `patchStrategicMerge` for anything shaped like the target object, and `patchesJson6902` only when you need exact list positions.
> - **Expecting `mutate` to fix objects that already exist.** A plain mutate rule only runs at admission, so it never sees anything created before it. Reaching existing objects needs the rule's `targets` field (mutate existing); the default does not do it.
> - **Using `validate` where `mutate` belongs.** Rejecting a Pod for a missing default that Kyverno could have supplied turns a solvable problem into an error for a developer. Set the default with `mutate`; keep `validate` for what really must be a human decision.

> *A mutate rule is a change on the way in, not a repair of what is already there, which is why the Pod that is older than your policy stays exactly as it was.*
