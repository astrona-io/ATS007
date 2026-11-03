# Question

Solve this question on: `terminal`

Astronaut, the `payments` planet (namespace) needs to know which team owns every ship (Pod) that launches there. Kyverno v1.19.1 is installed and running, and the `payments` namespace already exists. No policies exist yet.

1.  Write a `ClusterPolicy` named `require-team-label` that requires every Pod in the `payments` namespace to carry a non-empty `team` label. Use `validationFailureAction: Enforce`.
2.  Exclude the `kube-system` namespace from this policy.
3.  Apply the policy with `kubectl apply -f`.
4.  Attempt to create a Pod named `no-team-pod` in the `payments` namespace with no `team` label, and confirm the API server rejects it.
5.  Create a Pod named `has-team-pod` in the `payments` namespace with the label `team: checkout`, and confirm it is admitted successfully.

The grader reads the policy (it must be in `Enforce` mode and mention `kube-system`), checks that `no-team-pod` does not exist, and checks that `has-team-pod` exists with a `team` label.
