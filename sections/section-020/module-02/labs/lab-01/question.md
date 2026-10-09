# Question

Solve this question on: `terminal`

Astronaut, the `releases` planet only launches ships for known environments. The list of allowed environments is pinned on the planet's notice board, so the team can change it without touching the rule book. Kyverno v1.19.1 is installed and running.

The `releases` namespace already exists, and a ConfigMap named `allowed-environments` already exists in it, holding an allow-list of values under the key `values` (a comma-separated string: `dev,staging,prod`).

1.  Author a namespaced Kyverno `Policy` named `check-env-label` in the `releases` namespace with a rule that reads the `allowed-environments` ConfigMap via `context[].configMap`.
2.  The rule must deny (`validationFailureAction: Enforce`) any `Pod` created in `releases` whose `env` label value is not present in the ConfigMap's allow-list.
3.  The rule's `validate.message` must name the specific offending `env` value that was rejected.
4.  Apply your policy, then confirm a `Pod` named `bad-release` with label `env=qa` is rejected, and a `Pod` named `good-release` with label `env=staging` is accepted.

The grader checks that the policy's first rule has `allowed-environments` as its first `context` ConfigMap, that `bad-release` does not exist, and that `good-release` exists with `env=staging`.
