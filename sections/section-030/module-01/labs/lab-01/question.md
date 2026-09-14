# Question

Solve this question on: `terminal`

1.  Create a `ClusterPolicy` named `require-configmap-label` that **validates** `ConfigMap` resources in `Enforce` mode: every ConfigMap must carry the label `managed-by`. Give the rule a clear `validationFailureAction: Enforce` and a helpful `message`.
2.  Apply the policy, then inspect the live `validatingwebhookconfigurations` object Kyverno manages and confirm a rule entry now exists for `configmaps` (it did not exist before your policy was applied).
3.  Confirm enforcement: attempt to create a ConfigMap named `bad-config` in the `default` namespace **without** the `managed-by` label, and confirm the API server rejects it.
4.  Create a second ConfigMap named `good-config` in the `default` namespace **with** the label `managed-by: platform-team`, and confirm it is admitted successfully.
