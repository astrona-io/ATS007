# Question

Solve this question on: `terminal`

1.  Write a `ClusterPolicy` named `require-team-label` that requires every Pod in the `payments` namespace to carry a non-empty `team` label. Use `validationFailureAction: Enforce`.
2.  Exclude the `kube-system` namespace from this policy.
3.  Apply the policy with `kubectl apply -f`.
4.  Attempt to create a Pod named `no-team-pod` in the `payments` namespace with no `team` label, and confirm the API server rejects it.
5.  Create a Pod named `has-team-pod` in the `payments` namespace with the label `team: checkout`, and confirm it is admitted successfully.
