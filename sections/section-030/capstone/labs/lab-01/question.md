# Question

Solve this question on: `terminal`

The namespace `payments` already exists and already contains a running Deployment named `ledger-api` with no `data-classification` label.

1.  Create a `ClusterPolicy` named `require-data-classification` that validates Deployments in the `payments` namespace carry a `data-classification` label. Start it in `validationFailureAction: Audit` mode with `background: true`.
2.  Confirm Kyverno's live `validatingwebhookconfigurations` object now carries a rule entry covering `deployments` (it may already be there from other policies — confirm it, don't assume it).
3.  Confirm a `PolicyReport` in the `payments` namespace records a `fail` result for `ledger-api` against your rule, without `ledger-api` being touched in any way.
4.  Patch the policy to `validationFailureAction: Enforce`.
5.  Attempt to create a new Deployment named `ledger-api-v2` in `payments` **without** the label, and confirm it is rejected. Then create `ledger-api-v3` **with** `data-classification: restricted` and confirm it is admitted.
