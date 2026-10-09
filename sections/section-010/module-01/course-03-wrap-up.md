# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the shape of a Kyverno policy: the two policy kinds, the rules inside them, and how each rule picks the objects it checks.

**From [ClusterPolicy vs Policy & Rule Anatomy](./course-01-clusterpolicy-vs-policy-and-rule-anatomy.md):**

- A Kyverno policy is a normal Kubernetes object. `kubectl explain clusterpolicy.spec.rules` reads its schema from the cluster.
- A `ClusterPolicy` reaches the whole cluster; a `Policy` only reaches its own namespace. `kubectl api-resources --api-group=kyverno.io` shows this in the `NAMESPACED` column.
- From Kyverno v1.19, every command on these kinds prints a deprecation warning. It is not an error.
- Every rule has a `match` block and exactly one action: `validate`, `mutate`, `generate` or `verifyImages`.
- `Enforce` rejects a failing object; `Audit` admits it and records the failure in a `PolicyReport`.

**From [Match, Exclude & Resource Selection](./course-02-match-exclude-and-resource-selection.md):**

- `match` filters by kinds, namespaces, label selector, names or the requesting user. Filters in one `resources` entry are ANDed; entries under `any` are ORed.
- `exclude` has the same shape and takes objects away from what `match` selected.
- A selector that matches nothing fails silently. Check the real labels with `--show-labels` first.
- A broad `ClusterPolicy` should exclude `kyverno` and usually `kube-system`.

## Your mission

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [ClusterPolicy Label Enforcement](./labs/lab-01/README.md) | Match, Exclude & Resource Selection | write a scoped `ClusterPolicy` that blocks a Pod without a `team` label and admits one with it |

If you skipped it, go back to it now. It is short.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. A team wants a rule that only they control, for their own namespace. Which policy kind do they use?</summary>

A `Policy`. It lives in their namespace and can only match objects in that namespace. A `ClusterPolicy` would reach the whole cluster.
</details>

<details>
<summary>2. Which command shows you whether a Kyverno kind is namespaced?</summary>

`kubectl api-resources --api-group=kyverno.io`. The `NAMESPACED` column is `false` for `clusterpolicies` and `true` for `policies`.
</details>

<details>
<summary>3. Can one rule both <code>mutate</code> and <code>validate</code> an object?</summary>

No. A rule has exactly one action. Write a `mutate` rule and a separate `validate` rule. Kyverno runs all mutate rules before any validate rules.
</details>

<details>
<summary>4. A policy is in <code>Audit</code> mode and a Pod breaks its rule. What happens to the Pod, and where do you see the result?</summary>

The Pod is created. The failure is written to a `PolicyReport` in the Pod's namespace, which you read with `kubectl get policyreport -n <namespace>`.
</details>

<details>
<summary>5. Your rule selects namespaces with <code>env=Production</code>, and it never fires. Nothing reports an error. What do you check first?</summary>

The real labels, with `kubectl get namespaces --show-labels`. The playground uses `env=production` in lower case, so the selector matches nothing, and a selector that matches nothing fails silently.
</details>

<details>
<summary>6. Why should a broad <code>ClusterPolicy</code> on Pods exclude the <code>kyverno</code> namespace?</summary>

Otherwise the rule also checks Kyverno's own Pods. When they restart, the policy can block them, and the admission controller locks itself out.
</details>

<details>
<summary>7. You see <code>Warning: kyverno.io/v1 ClusterPolicy is deprecated</code> after <code>kubectl apply</code>. Did the apply fail?</summary>

No. The API server prints this warning on every command for these kinds from Kyverno v1.19. The policy was stored and is enforced.
</details>

## Clean up the playground

Your playground is a whole Kubernetes cluster running on your machine. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy section-010-module-01-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-007-lab-001
```

Run `astrona list` once more. Neither name should appear any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *A kind, a list of rules, a `match` block and one action: read those four things, and you can explain any Kyverno policy.*
