# Solution Walkthrough

## Step 1: Write the policy

```yaml
# clusterpolicy-require-secret-owner.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-secret-owner
spec:
  validationFailureAction: Enforce
  failurePolicy: Ignore
  webhookTimeoutSeconds: 15
  background: true
  rules:
    - name: check-owner-label
      match:
        any:
          - resources:
              kinds:
                - Secret
              namespaces:
                - vault
      validate:
        message: "Every Secret in vault needs an owner label."
        pattern:
          metadata:
            labels:
              owner: "?*"
```

```bash
kubectl apply -f clusterpolicy-require-secret-owner.yaml
```

## Step 2: Read the webhook

```bash
kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg \
  -o jsonpath='{range .webhooks[*]}{.name}{" "}{.failurePolicy}{" "}{.timeoutSeconds}{"\n"}{end}'
```

One line shows `Ignore` and `15`.

## Step 3: Prove both outcomes

```bash
kubectl create secret generic bad-secret --from-literal=k=v -n vault
```

This is denied by `check-owner-label`. Save the next file as `secret-good-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: good-secret
  namespace: vault
  labels:
    owner: ops
stringData:
  k: v
```

```bash
kubectl apply -f secret-good-secret.yaml
```

Run `astrona submit` to grade the lab.
