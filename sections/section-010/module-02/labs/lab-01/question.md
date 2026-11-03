# Question

Solve this question on: `terminal`

Astronaut, ships keep launching on the `storefront` planet without saying how much fuel (CPU and memory) they need. Kyverno v1.19.1 is installed and running. The namespace `storefront` already exists, with a running Deployment named `legacy-app` whose container sets no CPU or memory `requests` or `limits`.

1.  Write a `ClusterPolicy` named `require-container-resources` with a `foreach` validate rule requiring every container in a Pod to set `resources.requests` and `resources.limits` for both `cpu` and `memory`. Scope it to the `storefront` namespace. Use `validationFailureAction: Enforce` and `background: true`.
2.  Apply the policy.
3.  Confirm that creating a new non-compliant Pod named `bad-pod` in `storefront` is blocked.
4.  Wait for the background scan to run, then confirm `kubectl get policyreport -n storefront` reports a violation for the pre-existing `legacy-app` Deployment, without `legacy-app` itself being deleted or changed.

The grader checks that the policy uses `foreach` and `Enforce`, that `bad-pod` does not exist, that `legacy-app` still exists, and that a `PolicyReport` in `storefront` mentions `legacy-app`. It waits up to two minutes for that report.
