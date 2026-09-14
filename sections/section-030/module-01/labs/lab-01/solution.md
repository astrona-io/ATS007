# Solution Walkthrough

Follow these steps against the kind cluster's `kubectl` context:

---

## Step 1: Write the ClusterPolicy

```yaml
# require-configmap-label.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-configmap-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-managed-by-label
      match:
        any:
          - resources:
              kinds:
                - ConfigMap
      validate:
        message: "ConfigMap resources must carry a 'managed-by' label."
        pattern:
          metadata:
            labels:
              managed-by: "?*"
```

`"?*"` is Kyverno's pattern-matching wildcard meaning "any non-empty string" — this requires the key to exist with some value, not one specific value.

---

## Step 2: Apply the Policy and Inspect the Webhook

```bash
kubectl apply -f require-configmap-label.yaml
kubectl get clusterpolicy require-configmap-label
```

Now check the live validating webhook Kyverno manages:

```bash
kubectl get validatingwebhookconfigurations kyverno-resource-validating-webhook-cfg -o yaml | grep -A5 'resources:'
```

You should see a `resources` list containing `configmaps` that was not present before this policy existed — proof that Kyverno's webhook reconciliation reacted to your new policy.

---

## Step 3: Confirm the Block

```bash
kubectl create configmap bad-config --from-literal=key=value -n default
```

Expect a rejection referencing your policy's `message`:

```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource ConfigMap/default/bad-config was blocked due to the following policies

require-configmap-label:
  check-managed-by-label: 'validation error: ConfigMap resources must carry a
    ''managed-by'' label. rule check-managed-by-label failed at path /metadata/labels/managed-by/'
```

---

## Step 4: Confirm the Allow

```bash
kubectl create configmap good-config --from-literal=key=value -n default \
  --dry-run=client -o yaml | \
  kubectl label -f - --local -o yaml managed-by=platform-team | \
  kubectl apply -f -
```

Or more simply, write it as a manifest with the label already present and `kubectl apply -f` it. Confirm it exists:

```bash
kubectl get configmap good-config -n default --show-labels
```

Expect `managed-by=platform-team` in the labels column and no error on creation.
