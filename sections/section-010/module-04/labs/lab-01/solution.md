# Solution Walkthrough

## Step 1: Apply the policy

```yaml
# clusterpolicy-require-pod-team-label.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-pod-team-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - shop
      validate:
        message: "Every Pod in shop must carry a team label."
        pattern:
          metadata:
            labels:
              team: "?*"
```

```bash
kubectl apply -f clusterpolicy-require-pod-team-label.yaml
```

Check it with `astrona submit`. Steps 3 and 4 are not done yet, so the check still fails.

## Step 2: See autogen work

```bash
kubectl create deployment web --image=registry.k8s.io/pause:3.9 -n shop
```

The Deployment is denied by the rule `autogen-check-team-label`.

## Step 3: Write the exception

```yaml
# policyexception-legacy-batch.yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: legacy-batch
  namespace: shop
spec:
  exceptions:
    - policyName: require-pod-team-label
      ruleNames:
        - check-team-label
  match:
    any:
      - resources:
          kinds:
            - Pod
          namespaces:
            - shop
          names:
            - legacy-batch
```

```bash
kubectl apply -f policyexception-legacy-batch.yaml
```

## Step 4: Prove both outcomes

```bash
kubectl run legacy-batch --image=registry.k8s.io/pause:3.9 -n shop
kubectl run other-batch --image=registry.k8s.io/pause:3.9 -n shop
```

The first command creates the Pod. The second is denied. Run `astrona submit` to grade the lab.
