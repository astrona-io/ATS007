# Question

Solve this question on: `terminal`

The folder `/root/lab` has a `base` directory with a `ClusterPolicy` named `require-owner-label` (`validationFailureAction: Audit`, annotation `policies.kyverno.io/severity: medium`) and a `kustomization.yaml`. The folder `/root/lab/overlays/prod` is empty. Kyverno is installed.

1.  Create `/root/lab/overlays/prod/kustomization.yaml` that uses `../../base` as its resource.
2.  In the overlay, set `validationFailureAction` to `Enforce`, change the severity annotation to `high`, and add the label `environment: prod`.
3.  Use `kubectl kustomize` to check the result, then apply the overlay with `kubectl apply -k`.
