# Solution Walkthrough

## Step 1: Write the overlay

```yaml
# /root/lab/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
labels:
  - pairs:
      environment: prod
patches:
  - target:
      kind: ClusterPolicy
      name: require-owner-label
    patch: |-
      - op: replace
        path: /spec/validationFailureAction
        value: Enforce
      - op: replace
        path: /metadata/annotations/policies.kyverno.io~1severity
        value: high
```

## Step 2: Check the result

```bash
cd /root/lab
kubectl kustomize overlays/prod
```

The output must show `Enforce`, `high` and the `environment: prod` label.

## Step 3: Apply it

```bash
kubectl apply -k overlays/prod
```

Run `astrona submit` to grade the lab.
