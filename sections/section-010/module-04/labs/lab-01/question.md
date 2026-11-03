# Question

Solve this question on: `terminal`

The `shop` namespace exists. Kyverno is installed with policy exceptions switched on.

1.  Create a `ClusterPolicy` named `require-pod-team-label` with `validationFailureAction: Enforce`. It has one rule named `check-team-label` that matches `Pod` in the `shop` namespace and requires a non-empty `team` label.
2.  Prove that a Deployment in `shop` whose Pod template has no `team` label is rejected, without writing any Deployment rule yourself.
3.  Create a `PolicyException` named `legacy-batch` in `shop` that lets a Pod named `legacy-batch` skip the `check-team-label` rule.
4.  Create a Pod named `legacy-batch` in `shop` without a `team` label. It must be admitted. A Pod named `other-batch` without a label must still be rejected.
