# Part 1 — Variables & JMESPath Basics

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Context: configMap & apiCall](./course-02-context-configmap-and-apicall.md).

A Kyverno variable is a `{{ }}`-delimited expression written anywhere a string is expected in a rule — inside `pattern`, inside `validate.message`, inside a `mutate` overlay. At evaluation time, Kyverno replaces the whole `{{ ... }}` block with the result of running the enclosed [JMESPath](https://jmespath.org/) expression against the data available to that rule.

## What data is available

Three sources are always present, with no `context` block required:

- **`request.object`** — the resource as submitted in this admission request (the new state, for `CREATE`/`UPDATE`).
- **`request.oldObject`** — the resource's previous state, populated only on `UPDATE`/`DELETE`.
- **`request.operation`** — the string `CREATE`, `UPDATE`, `DELETE`, or `CONNECT`.

The intimidating part of an expression like `{{ request.object.metadata.labels.env }}` is the syntax, not the idea. `request.object` is *literally the JSON of the resource being admitted* — the same JSON `kubectl` hands you for any object already in the cluster. The expression is a path through that document and nothing more, which means the reliable way to write one is not to guess from documentation, but to look at the object first and read the path off what you see.

> [!TIP]
> **Try it — look at the document a variable walks**
>
> ```sh
> kubectl get pod reporting -n tenant-blue -o json | head -25
> ```
>
> Expect something like:
>
> ```text
> {
>     "apiVersion": "v1",
>     "kind": "Pod",
>     "metadata": {
>         "labels": {
>             "app": "reporting",
>             "env": "staging"
>         },
>         "name": "reporting",
>         "namespace": "tenant-blue",
> ...
> ```
>
> Field ordering, timestamps and generated fields vary. Trace the path down from the top: `metadata` → `labels` → `env`. Inside a rule matching this Pod, `{{ request.object.metadata.labels.env }}` resolves to `staging` — the same walk, written as a string.

```yaml
validate:
  message: "Pod {{ request.object.metadata.name }} is missing a 'team' label."
  pattern:
    metadata:
      labels:
        team: "?*"
```

Here `{{ request.object.metadata.name }}` resolves to the actual Pod name at evaluation time, so a user blocked by this rule sees their own resource's name quoted back at them instead of a generic message.

## JMESPath in three examples

JMESPath is a query language for JSON (and, by extension, for the JSON-like structure every Kubernetes object already has). You do not need the whole specification to be productive — three patterns cover the large majority of Kyverno rules:

1. **Dot-path field access** — `request.object.metadata.labels.team` walks straight down nested maps, identical to how you would read the same value in the YAML itself.
2. **Indexing and wildcards over lists** — `request.object.spec.containers[].image` collects the `image` field from *every* entry in the `containers` list into an array, which is exactly what you need to check something about every container in a Pod without knowing in advance how many there are.
3. **Filters** — `request.object.spec.containers[?resources.limits.memory==null].name` collects the names of only the containers that are *missing* a memory limit, letting a `validate.message` name the exact offenders instead of failing the whole Pod with no detail.

> [!TIP]
> **Try it — resolve a variable and see it interpolated into a rejection**
>
> ```sh
> kubectl apply -f - <<'EOF'
> apiVersion: kyverno.io/v1
> kind: ClusterPolicy
> metadata:
>   name: name-in-message-demo
> spec:
>   validationFailureAction: Enforce
>   rules:
>     - name: require-team-label
>       match:
>         any:
>           - resources:
>               kinds: [Pod]
>       validate:
>         message: "Pod '{{ request.object.metadata.name }}' is missing a 'team' label."
>         pattern:
>           metadata:
>             labels:
>               team: "?*"
> EOF
> kubectl run demo-pod --image=nginx --restart=Never
> ```
>
> Expect something like:
>
> ```text
> Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
>
> name-in-message-demo:
>   require-team-label: 'validation error: Pod ''demo-pod'' is missing a ''team'' label. rule require-team-label failed...'
> ```
>
> The literal Pod name `demo-pod` appears inside the message — resolved from `{{ request.object.metadata.name }}` at the moment this specific request was evaluated, not hardcoded in the policy.

> [!WARNING]
> **Common pitfalls**
>
> - **Quoting a variable that isn't a plain string.** `{{ request.object.spec.containers[].image }}` resolves to a YAML *list*, not a string. Writing `message: "Images used: {{ request.object.spec.containers[].image }}"` will render as the list's string form (e.g. `[nginx:latest]`) rather than a clean comma-separated line — usually acceptable for a message, but a silent bug if you expected a plain scalar somewhere else in the rule, such as inside a `pattern` block expecting one image string.
> - **Assuming an expression that resolves to nothing fails loudly.** Depending on where it sits, an unresolved variable typically causes the rule to be *skipped* rather than to reject the request — so a policy you believe is enforcing can quietly enforce nothing. Test with a resource you expect to be rejected, not only with one you expect to pass.

*A `{{ }}` block is JMESPath run against the request, the resource, or `context` — resolved once, at evaluation time, and substituted as plain text or structured data depending on where you use it.*

## Reference

- [JMESPath specification & interactive tutorial](https://jmespath.org/tutorial.html) — practice writing expressions against sample JSON before wiring them into a policy.
- [Kyverno variables docs](https://kyverno.io/docs/writing-policies/variables/) — the full list of built-in variables beyond `request.*`.
