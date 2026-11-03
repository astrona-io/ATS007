# Preconditions & Allow-Lists

Astronaut, you can now fill variables from the request and from `context` entries. This part adds the gate in front of a rule, `preconditions`, and then puts the pieces together: a ConfigMap allow-list, a check against it, and a rejection message that names the value at fault.

## preconditions: deciding whether the rule runs at all

`preconditions` are an "only inspect if ..." gate in front of the rule. Here is one that lets a rule run only when an object is being created:

```yaml
preconditions:
  all:
    - key: "{{ request.operation }}"
      operator: Equals
      value: CREATE
```

`preconditions` is an `any` or `all` block of conditions, with the same operators as a `deny.conditions` block. Kyverno checks it *before* the rule's main body (`validate`, `mutate` or `generate`). If it comes out false, the rule is skipped for this request: no violation, no report entry, nothing.

That is different from a failing `validate.pattern`, which produces a real denial or audit finding. Use `preconditions` to say "this rule does not apply here", for example to skip mutate rules on `DELETE`, when there is nothing left to change. Use `validate` to say "this rule applies, and the object fails it".

## An allow-list with the bad value named

A common rule combines everything in this module: load an allow-list from a ConfigMap, check a label against it, and tell the user exactly which value was refused. The building blocks fit together in three pieces.

### The context entry loads the list

The rule loads a ConfigMap named `allowed-environments`, whose key `values` holds a comma-separated list such as `dev,staging,prod`:

```yaml
context:
  - name: allowed
    configMap:
      name: allowed-environments
      namespace: releases
```

After this, `{{ allowed.data.values }}` is the text `dev,staging,prod`.

### The deny condition checks the label against it

The ConfigMap stores one string, but the check needs a list. The JMESPath function `split` cuts the string at each comma:

```yaml
deny:
  conditions:
    all:
      - key: "{{ request.object.metadata.labels.env }}"
        operator: AnyNotIn
        value: "{{ split(allowed.data.values, ',') }}"
```

`split(allowed.data.values, ',')` turns `dev,staging,prod` into the list `dev`, `staging`, `prod`. `AnyNotIn` then denies whenever the Pod's `env` label value is not found in that list.

### The message names the value

The message uses two variables, so the user sees both the value they sent and the list they should choose from:

```yaml
message: "env label '{{ request.object.metadata.labels.env }}' is not one of the allowed values: {{ allowed.data.values }}"
```

Both the refused value and the full allowed list come from variables. The ConfigMap, not the policy YAML, decides what counts as allowed.

<!-- astrona:playground:renew -->

### See a comma-separated value in your playground

Your playground's `deploy-settings` ConfigMap stores its allowed regions the same way, as one comma-separated string. Print just that value:

```sh
kubectl get configmap deploy-settings -n tenant-blue -o jsonpath='{.data.allowed-regions}'
```

Look for the two regions joined by a comma in a single line of text. That single string is what `split` would turn into a list inside a rule.

## Common pitfalls

> [!WARNING]
> - **Confusing `preconditions` with `deny.conditions`.** `preconditions` decide whether the rule runs at all; `deny.conditions` decide whether a request the rule *did* run on is rejected. Putting rejection logic in `preconditions` gives you a rule that skips instead of blocking.
> - **Comparing a label with the raw ConfigMap string.** `dev,staging,prod` is one string. Use `split` to make a list before `AnyNotIn` or `AnyIn`.
> - **A message that only says "not allowed".** Put the refused value and the allowed list into `validate.message` with variables, so the user knows what to fix.

> *`preconditions` decide whether a rule runs; `context`, `split` and a named message turn an outside list into a rule that explains itself.*

## Your mission: Context & Variables Validation

You can now load data with a `context` entry, compare against it with variables and JMESPath, and name the bad value in the message. The mission asks you to write a namespaced `Policy` that checks a Pod's `env` label against a ConfigMap allow-list, names the refused value, and proves one Pod is rejected and another admitted.

The mission runs in its own training solar system, so first pause your playground. Nothing in it is lost:

```sh
astrona stop section-020-module-02-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS007.git -c sections/section-020/module-02/labs/lab-01
```

Read the task in [question.md](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-007-lab-006
astrona start section-020-module-02-playground
```
