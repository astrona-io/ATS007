# Summary

A policy is a file you can describe, sort and reuse. Annotations describe it to people, and Kustomize reuses one base across environments.

## What you learned

The `policies.kyverno.io/` annotations (`title`, `category`, `severity`, `subject`, `description`) are notes for people and tools. They do not change how the policy runs. You read them with `kubectl get ... -o jsonpath` and list them with `custom-columns`.

A Kustomize overlay has a `kustomization.yaml` that lists the base under `resources` and the changes under `patches` and `labels`. `kubectl kustomize` builds and prints, `kubectl diff -k` previews, and `kubectl apply -k` applies. The key facts to remember are these:

- Only `spec` fields such as `validationFailureAction` change behavior.
- In a JSON Patch path, `/` inside a key is written `~1`.
- `kubectl diff` exits with 1 when there are differences.

## Your mission

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Policy Overlay Lab](./labs/lab-01/README.md) | Kustomize overlays for policies | Build an `Enforce` production policy from an `Audit` base |

## Check yourself

<details>
<summary>1. Does setting <code>policies.kyverno.io/severity: high</code> make a policy block more resources?</summary>

No. It is a note. Only fields under `spec`, such as `validationFailureAction`, change behavior.
</details>

<details>
<summary>2. Which command shows what an overlay would change in the live cluster?</summary>

`kubectl diff -k <overlay folder>`.
</details>

<details>
<summary>3. How do you write the annotation key <code>policies.kyverno.io/severity</code> in a JSON Patch path?</summary>

`/metadata/annotations/policies.kyverno.io~1severity`. The slash in the key becomes `~1`.
</details>

## Clean up

Run `astrona list`, then destroy the playground and the mission if they are still listed:

```sh
astrona destroy section-020-module-04-playground
astrona destroy ats-007-lab-016
```

> *One base blueprint, one set of mission notes per fleet.*

<!-- astrona:playground:destroy -->
