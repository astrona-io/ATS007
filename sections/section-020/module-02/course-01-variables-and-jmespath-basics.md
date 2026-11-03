# Variables & JMESPath Basics

Astronaut, a Kyverno variable is a blank in the rule that Kyverno fills from the launch request. You write it as a `{{ }}` expression anywhere a rule expects a string: inside a `pattern`, inside `validate.message`, inside a `mutate` overlay. When Kyverno checks a request, it replaces the whole `{{ ... }}` block with the result of the JMESPath expression inside it, run against the data that rule can see.

## What data is available

Three sources are always there, with no `context` block needed:

- **`request.object`**: the object as sent in this admission request (the new state, for `CREATE` and `UPDATE`).
- **`request.oldObject`**: the object's previous state, filled only on `UPDATE` and `DELETE`.
- **`request.operation`**: the text `CREATE`, `UPDATE`, `DELETE` or `CONNECT`.

The hard part of an expression like `{{ request.object.metadata.labels.env }}` is the syntax, not the idea. `request.object` is *the JSON of the object being admitted*, the same JSON `kubectl` shows you for any object already in the cluster. The expression is just a path through that document. So the reliable way to write one is not to guess, but to look at the object first and read the path off what you see.

<!-- astrona:playground:renew -->

### Look at the document a variable walks

Print the playground's `reporting` Pod as JSON:

```sh
kubectl get pod reporting -n tenant-blue -o json | head -25
```

You should see something like:

```text
{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
        "labels": {
            "app": "reporting",
            "env": "staging"
        },
        "name": "reporting",
        "namespace": "tenant-blue",
...
```

Field order, timestamps and generated fields will differ. Trace the path down from the top: `metadata`, then `labels`, then `env`. Inside a rule that matches this Pod, `{{ request.object.metadata.labels.env }}` becomes `staging`. It is the same walk, written as a string.

Here is a variable in a message:

```yaml
validate:
  message: "Pod {{ request.object.metadata.name }} is missing a 'team' label."
  pattern:
    metadata:
      labels:
        team: "?*"
```

`{{ request.object.metadata.name }}` becomes the real Pod name when the rule runs. A user blocked by this rule sees their own object's name in the message, not a generic text.

## JMESPath in three examples

JMESPath is a query language for JSON, and every Kubernetes object already has a JSON shape. You do not need the whole specification. Three patterns cover most Kyverno rules:

1. **Dotted field access**: `request.object.metadata.labels.team` walks straight down nested maps, just as you would read the value in the YAML itself.
2. **Lists with `[]`**: `request.object.spec.containers[].image` collects the `image` field from *every* entry in `containers` into a list. That is how you check something about every container without knowing how many there are.
3. **Filters**: `request.object.spec.containers[?resources.limits.memory==null].name` collects the names of only the containers that are *missing* a memory limit. A `validate.message` can then name the exact containers at fault.

### See a variable filled into a rejection

Watch Kyverno fill a variable into a real rejection message.

Save this as `clusterpolicy-name-in-message-demo.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: name-in-message-demo
spec:
  validationFailureAction: Enforce
  rules:
    - name: require-team-label
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "Pod '{{ request.object.metadata.name }}' is missing a 'team' label."
        pattern:
          metadata:
            labels:
              team: "?*"
```

Apply it:

```sh
kubectl apply -f clusterpolicy-name-in-message-demo.yaml
```

Then try to launch a Pod with no `team` label:

```sh
kubectl run demo-pod --image=nginx --restart=Never
```

You should see something like:

```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

name-in-message-demo:
  require-team-label: 'validation error: Pod ''demo-pod'' is missing a ''team'' label. rule require-team-label failed...'
```

The real Pod name `demo-pod` appears in the message. The Kyverno admission controller filled it from `{{ request.object.metadata.name }}` for this one request; it is not written into the policy. The output above is shortened at `failed...`.

This demo policy matches every Pod in the cluster. Remove it when you are done:

```sh
kubectl delete clusterpolicy name-in-message-demo
```

## Common pitfalls

> [!WARNING]
> - **Putting a list where a single value is expected.** `{{ request.object.spec.containers[].image }}` gives a *list*, not a string. In a message it shows as the list's text form (for example `[nginx:latest]`), which is usually fine. Inside a `pattern` that expects one image string, it is a silent bug.
> - **Expecting an expression that finds nothing to fail loudly.** Depending on where it sits, an expression that resolves to nothing usually makes Kyverno *skip* the rule instead of rejecting the request. A policy you think is enforcing can quietly enforce nothing. Always test with an object you expect to be rejected, not only one you expect to pass.
> - **Guessing a path instead of reading it.** Print the object with `-o json` and copy the path you see.

> *A `{{ }}` block is JMESPath run against the request, the object or a `context` entry, filled in once when the rule runs.*
