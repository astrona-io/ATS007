# Question

Solve this question on: `terminal`

The `prod` namespace exists and Kyverno is installed. No registry is needed, because Pods are judged at admission.

1.  Create a `ClusterPolicy` named `restrict-image-sources` with `validationFailureAction: Enforce` and three `validate` rules for Pods in `prod`: `allowed-registry` (only `registry.k8s.io/*`), `require-tag` (the image must contain a tag) and `no-latest-tag` (the tag must not be `latest`).
2.  Use `kubectl run probe ... -n prod --dry-run=server` to prove `nginx:1.27`, `registry.k8s.io/pause` and `registry.k8s.io/pause:latest` are all rejected.
3.  Prove that `registry.k8s.io/pause:3.9` is accepted.
