# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about rules that read data: variables from the request, outside data from `context` entries, and the `preconditions` gate in front of a rule.

**From [Variables & JMESPath Basics](./course-01-variables-and-jmespath-basics.md):**

- A `{{ }}` variable holds a JMESPath expression that Kyverno fills in when the rule runs.
- `request.object`, `request.oldObject` and `request.operation` are always available.
- Read paths off the real object with `kubectl get ... -o json`. `[]` collects from every list item, and `[?...]` filters.
- A variable in `validate.message` lets the rejection name the user's own object.
- An expression that finds nothing usually skips the rule instead of rejecting.

**From [Context: configMap & apiCall](./course-02-context-configmap-and-apicall.md):**

- `context[].configMap` loads a ConfigMap, read as `<name>.data.<key>`; editing the ConfigMap changes the rule's behaviour at once.
- `context[].apiCall` asks the API server (or another web address) a live question on every request; it costs more than a ConfigMap lookup.
- An `apiCall` runs with Kyverno's service account and its cluster roles, not with your permissions. Missing permissions show up as empty results.

**From [Preconditions & Allow-Lists](./course-03-preconditions-and-allow-lists.md):**

- `preconditions` decide whether a rule runs at all; a false precondition skips the rule with no report.
- `split(allowed.data.values, ',')` turns a comma-separated ConfigMap value into a list for `AnyNotIn`.
- A good rejection message names both the refused value and the allowed list.

## Your mission

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Context & Variables Validation](./labs/lab-01/README.md) | Preconditions & Allow-Lists | check a Pod's `env` label against a ConfigMap allow-list and name the refused value in the message |

If you skipped it, go back to it now. It is short.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Which variable holds the object as it was before an update?</summary>

`request.oldObject`. It is filled only on `UPDATE` and `DELETE`. `request.object` holds the new state.
</details>

<details>
<summary>2. Write the expression that collects the image of every container in a Pod.</summary>

`request.object.spec.containers[].image`. The `[]` collects the field from every list item.
</details>

<details>
<summary>3. A platform team wants to change the list of allowed regions without editing the policy. <code>configMap</code> or <code>apiCall</code>?</summary>

`configMap`. The team edits the ConfigMap, and the next request uses the new list. `apiCall` is for live, request-specific questions.
</details>

<details>
<summary>4. Your <code>apiCall</code> returns nothing, but <code>kubectl get</code> on the same object works for you. Why?</summary>

The `apiCall` runs as Kyverno's service account. Kyverno's cluster roles may not allow it to read that kind of object. Check them with `kubectl get clusterrole | grep kyverno`.
</details>

<details>
<summary>5. A rule's <code>preconditions</code> come out false for a request. Is the request rejected?</summary>

No. The rule is skipped for that request: no violation and no report entry.
</details>

<details>
<summary>6. Why does an allow-list check use <code>split(allowed.data.values, ',')</code>?</summary>

The ConfigMap stores one string such as `dev,staging,prod`. `split` turns it into a list, so `AnyNotIn` can check whether the label value is in it.
</details>

<details>
<summary>7. You tested your new rule only with a Pod you expected to pass, and it passed. What have you not proved?</summary>

That the rule enforces anything. An expression that resolves to nothing can make Kyverno skip the rule. Always test with an object you expect to be rejected too.
</details>

## Clean up the playground

Your playground is a whole Kubernetes cluster running on your machine. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy section-020-module-02-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-007-lab-006
```

Run `astrona list` once more. Neither name should appear any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *Read the form with JMESPath, check the notice board with `context`, and decide at the gate with `preconditions`: that is how a rule reaches beyond the one object in front of it.*
