# Question

Solve this question on: `terminal`

The `vault` namespace exists and Kyverno is installed.

1.  Create a `ClusterPolicy` named `require-secret-owner` with `validationFailureAction: Enforce` that requires a non-empty `owner` label on Secrets in the `vault` namespace.
2.  Set `failurePolicy: Ignore` and `webhookTimeoutSeconds: 15` on the policy.
3.  Read the `kyverno-resource-validating-webhook-cfg` configuration and confirm a webhook with failure policy `Ignore` and timeout 15 exists.
4.  Create a Secret named `bad-secret` in `vault` without the label and confirm it is rejected. Create a Secret named `good-secret` with the label `owner: ops` and confirm it is admitted.
