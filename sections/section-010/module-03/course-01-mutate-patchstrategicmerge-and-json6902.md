# Part 1 — Mutate: patchStrategicMerge & patchesJson6902

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Generate: Clone & Synchronize](./course-02-generate-clone-and-synchronize.md).

Mutate rules run before validate rules in Kyverno's admission flow, which is what makes them useful for defaults: a mutate rule can fill in a missing field, and a later validate rule can then accept the now-complete resource without ever bothering the developer who submitted it.

## Mutation happens on the way in

A `mutate` rule rewrites a resource during admission, before it is persisted. The consequence that surprises people is the flip side: a resource that was admitted *before* the rule existed was never passed through it, so it stays exactly as it was. Mutation is not a reconciliation loop over the cluster's contents.

The playground's seeded `existing-api` Pod exists precisely to make this visible. Whatever mutate rule you write later, this Pod predates it — so it becomes the control case against any Pod you create afterwards.

> [!TIP]
> **Try it — record the "before" state**
>
> ```sh
> kubectl -n catalog get pod existing-api --show-labels
> ```
>
> Expect something like:
>
> ```text
> NAME           READY   STATUS    RESTARTS   AGE   LABELS
> existing-api   1/1     Running   0          5m    run=existing-api
> ```
>
> One label, added by `kubectl run`. When you later apply a mutate rule that adds a label to Pods in `catalog`, re-running this command shows this Pod unchanged — while a newly created Pod picks the label up. That contrast is the whole point of the seeded resource.

## Two patch styles, and why both exist

`patchStrategicMerge` describes the shape you want and lets Kubernetes merge it in by key. It is the natural fit for adding a label, an annotation, or a defaulted field, because you write the same nested YAML you would have written by hand.

`patchesJson6902` takes explicit RFC 6902 operations — `add`, `replace`, `remove` — each with a `path` and a `value`. You reach for it when position matters, most often when editing an array by index, which a key-based merge cannot express. As with validate's three mechanisms, both are peers under the same `mutate` block.

> [!TIP]
> **Try it — list what a mutate block accepts**
>
> ```sh
> kubectl explain clusterpolicy.spec.rules.mutate
> ```
>
> Expect something like:
>
> ```text
> KIND:       ClusterPolicy
> VERSION:    kyverno.io/v1
>
> FIELDS:
>   foreach                <[]Object>
>   patchStrategicMerge    <>
>   patchesJson6902        <string>
>   targets                <[]Object>
>   ...
> ```
>
> Field sets vary by Kyverno version. Note `targets` alongside the two patch styles — that is the field that extends mutation to resources other than the one being admitted, which is how mutation reaches existing resources when you genuinely need it to.

## `patchStrategicMerge`: overlay-style patching

`patchStrategicMerge` describes the change as an overlay — a fragment of the target resource's own shape, merged onto the incoming object. It reads almost exactly like the object it's patching.

```yaml
mutate:
  patchStrategicMerge:
    metadata:
      labels:
        managed-by: kyverno
```

Applied to any matching Pod, this merges the `managed-by: kyverno` label into `metadata.labels`, leaving every other label already on the Pod untouched. Strategic merge is the right tool whenever the change is "add or overwrite this field," including nested objects and Kubernetes-aware list merges (for example, adding an environment variable to a named container without disturbing the others).

> [!TIP]
> **Try it — see a label appear with no manual edit**
>
> ```sh
> kubectl run mutate-me --image=nginx:alpine -n catalog
> kubectl get pod mutate-me -n catalog --show-labels
> ```
>
> Expect `managed-by=kyverno` in the labels list even though your `kubectl run` command never mentioned it — the mutate rule added it in flight, before the object was ever persisted. Clean up with `kubectl delete pod mutate-me -n catalog --ignore-not-found`.

## `patchesJson6902`: precise, path-addressed patching

Some edits can't be expressed as a clean overlay — inserting into the middle of an array by index, or replacing one specific list element without touching its siblings. For those, Kyverno supports RFC 6902 JSON Patch via `patchesJson6902`:

```yaml
mutate:
  patchesJson6902: |-
    - op: add
      path: "/spec/containers/0/env/-"
      value:
        name: TRACE_ENABLED
        value: "true"
```

Each entry is an explicit operation (`add`, `replace`, `remove`, …) against an exact JSON Pointer path. The trailing `-` in the path means "append to the end of this array." Where `patchStrategicMerge` says "merge this shape in," `patchesJson6902` says "perform exactly this surgical edit, at exactly this path" — more verbose, but unambiguous about array positions in a way a merge overlay sometimes isn't.

> [!WARNING]
> **Common pitfalls**
>
> - **Reaching for `patchesJson6902` by default because it feels more "precise".** It makes simple label and annotation mutations far more verbose than they need to be. Default to `patchStrategicMerge` for anything shaped like the target object; reach for `patchesJson6902` specifically when you need exact array-index control that a merge overlay can't express.
> - **Expecting `mutate` to fix resources that already exist.** A plain mutate rule only runs on admission, so it never sees anything created before it. Reaching existing resources requires the rule's `targets` field (mutate-existing) — the default does not do it.
> - **Using `validate` where `mutate` belongs.** Rejecting a Pod for a missing default that Kyverno could have supplied turns a solvable problem into a developer-facing error. Default it with `mutate`; reserve `validate` for what genuinely must be a human decision.

> *A mutate rule is a rewrite on the way in, not a repair of what is already there — which is why the Pod that predates your policy stays exactly as it was.*

## Reference

- `kubectl explain clusterpolicy.spec.rules.mutate` — the live schema for both patch styles on your installed version.
- RFC 6902 (JSON Patch) — the operation vocabulary (`add`/`remove`/`replace`/`move`/`copy`/`test`) `patchesJson6902` is built on.
