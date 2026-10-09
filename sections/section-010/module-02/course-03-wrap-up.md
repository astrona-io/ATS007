# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the three ways a `validate` rule can express a check, and about the difference between checking new objects and checking objects that already exist.

**From [Pattern Validation & Deny Conditions](./course-01-pattern-validation-and-deny-conditions.md):**

- `pattern`, `deny` and `foreach` are options inside one `validate` block, not separate rule types.
- A `pattern` copies the object's shape. `"?*"` means "set and non-empty", `"*"` also accepts empty, `">=2"` compares numbers and `"!prod"` means "not prod".
- Every leaf in a pattern must match, so fields in one pattern are ANDed.
- `deny.conditions` handles logic across separate fields: `all` is AND, `any` is OR, and `{{ }}` variables read values from the request.

**From [foreach & Background Scans](./course-02-foreach-and-background-scans.md):**

- `foreach` walks through a list, such as `request.object.spec.containers`, and checks every item, so a second or third container cannot slip past.
- `background: true` re-checks objects that already exist and writes the results to a `PolicyReport` or `ClusterPolicyReport`. It never blocks.
- The background and reports controllers produce reports; the admission controller handles live requests.
- `Audit` plus `background: true` shows what a new rule would break before you switch to `Enforce`.

## Your mission

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [foreach Validate & Background Scan](./labs/lab-01/README.md) | foreach & Background Scans | block new Pods without requests and limits, and find an existing violation in a `PolicyReport` |

If you skipped it, go back to it now. It is short.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Which pattern value means "this label must be present and not empty"?</summary>

`"?*"`. The `?` needs at least one character and the `*` accepts the rest. `"*"` alone would also accept an empty value.
</details>

<details>
<summary>2. You need to reject Pods that use the <code>default</code> service account, except in <code>kube-system</code>. Pattern or deny?</summary>

`deny` with `conditions.all`: one condition checks the service account name, the other checks that the namespace is not `kube-system`. That is logic across two separate fields, which a pattern cannot express well.
</details>

<details>
<summary>3. A pattern checks <code>spec.containers[0].resources</code>. A Pod's second container has no limits. Does the Pod pass?</summary>

Yes, and that is the problem. Only the first container is checked. Use `foreach` with `list: "request.object.spec.containers"` to check every container.
</details>

<details>
<summary>4. A Deployment was running before you applied a policy with <code>background: true</code> in <code>Enforce</code> mode. Is it deleted or blocked?</summary>

Neither. Background scanning only reports. The violation appears in the namespace's `PolicyReport`; the Deployment keeps running untouched.
</details>

<details>
<summary>5. Background results never appear. Which Kyverno Deployments do you check first?</summary>

`kyverno-background-controller` and `kyverno-reports-controller`. They do the scanning and write the report objects. The admission controller is not involved.
</details>

<details>
<summary>6. Why is <code>Audit</code> with <code>background: true</code> a safe first step for a new rule?</summary>

It shows which existing objects would fail, and it records new failures too, without rejecting anything. You can fix what it finds before switching to `Enforce`.
</details>

## Clean up the playground

Your playground is a whole Kubernetes cluster running on your machine. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy section-010-module-02-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-007-lab-002
```

Run `astrona list` once more. Neither name should appear any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *Patterns for shape, conditions for logic, `foreach` for lists, and background scans for what was already there: that is the whole `validate` toolbox.*
