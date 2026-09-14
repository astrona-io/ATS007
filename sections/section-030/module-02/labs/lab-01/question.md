# Question

Solve this question on: `terminal`

The `analytics` namespace already exists and already contains a running Deployment named `legacy-etl` that has no `cost-center` label.

1.  Create a `ClusterPolicy` named `require-cost-center-label` that validates Deployments in the `analytics` namespace carry a `cost-center` label. Set `validationFailureAction: Audit` and `background: true`.
2.  Wait for the background scan to run, then confirm a `PolicyReport` in the `analytics` namespace shows a `fail` result for `legacy-etl` against your rule.
3.  Without deleting or editing `legacy-etl`, patch the policy to `validationFailureAction: Enforce`.
4.  Attempt to create a new Deployment named `legacy-etl-v2` in `analytics` **without** a `cost-center` label, and confirm the API server now rejects it.
