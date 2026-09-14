# Question

Solve this question on: `terminal`

The `kyverno` CLI is installed. The directory `/root/lab` already contains three files:
*   `require-team-label.yaml` — a `ClusterPolicy` with a single rule named `check-team-label`, requiring every Pod to carry a `team` label.
*   `good-pod.yaml` — a Pod named `good-pod` that **has** a `team` label.
*   `bad-pod.yaml` — a Pod named `bad-pod` that **does not** have a `team` label.

Everything in this task is done offline against those files. Do not apply the policy to the cluster.

1.  Use `kyverno apply` to evaluate the policy against **both** resource manifests in a single command, and observe which one passes and which one fails.
2.  In `/root/lab`, author a test suite file named `kyverno-test.yaml` (`apiVersion: cli.kyverno.io/v1alpha1`, `kind: Test`) that declares the policy under `policies`, both resources under `resources`, and a `results` list asserting the expected outcome for each resource — `good-pod` must be expected to `pass` and `bad-pod` must be expected to `fail`, both against the `check-team-label` rule of the `require-team-label` policy.
3.  Run `kyverno test .` from `/root/lab` and confirm every declared expectation is met.
