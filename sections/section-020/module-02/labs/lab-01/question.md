# Question

Solve this question on: `terminal`

The `releases` namespace already exists, and a ConfigMap named `allowed-environments` already exists in it holding an allow-list of values under the key `values` (a comma-separated string: `dev,staging,prod`). Kyverno is installed and running.

1.  Author a namespaced Kyverno `Policy` named `check-env-label` in the `releases` namespace with a rule that reads the `allowed-environments` ConfigMap via `context[].configMap`.
2.  The rule must deny (`validationFailureAction: Enforce`) any `Pod` created in `releases` whose `env` label value is not present in the ConfigMap's allow-list.
3.  The rule's `validate.message` must name the specific offending `env` value that was rejected.
4.  Apply your policy, then confirm a `Pod` named `bad-release` with label `env=qa` is rejected, and a `Pod` named `good-release` with label `env=staging` is accepted.
