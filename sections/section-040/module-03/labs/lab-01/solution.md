# Solution Walkthrough

## Step 1: Write the policy

```yaml
# clusterpolicy-restrict-image-sources.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-image-sources
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: allowed-registry
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - prod
      validate:
        message: "Images in prod must come from registry.k8s.io."
        pattern:
          spec:
            containers:
              - image: "registry.k8s.io/*"
    - name: require-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - prod
      validate:
        message: "Images in prod must have a tag."
        pattern:
          spec:
            containers:
              - image: "*:*"
    - name: no-latest-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - prod
      validate:
        message: "The latest tag is not allowed in prod."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

```bash
kubectl apply -f clusterpolicy-restrict-image-sources.yaml
```

## Step 2: Prove the rejections

```bash
kubectl run probe --image=nginx:1.27 -n prod --dry-run=server
kubectl run probe --image=registry.k8s.io/pause -n prod --dry-run=server
kubectl run probe --image=registry.k8s.io/pause:latest -n prod --dry-run=server
```

Each command is denied. The first fails `allowed-registry`, the second `require-tag` and the third `no-latest-tag`.

## Step 3: Prove the admission

```bash
kubectl run probe --image=registry.k8s.io/pause:3.9 -n prod --dry-run=server
```

The Pod is accepted. Run `astrona submit` to grade the lab.
