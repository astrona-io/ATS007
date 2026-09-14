# Solution Walkthrough

Follow these steps to build, apply, and verify the context-driven policy:

---

## Step 1: Inspect the Existing ConfigMap

```bash
kubectl get configmap allowed-environments -n releases -o yaml
```
Confirm it holds `data.values: dev,staging,prod`.

---

## Step 2: Author the Policy YAML

Create `check-env-label.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: check-env-label
  namespace: releases
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: env-must-be-allowed
      match:
        any:
          - resources:
              kinds:
                - Pod
      context:
        - name: allowed
          configMap:
            name: allowed-environments
            namespace: releases
      validate:
        message: "env label '{{ request.object.metadata.labels.env }}' is not one of the allowed values: {{ allowed.data.values }}"
        deny:
          conditions:
            all:
              - key: "{{ request.object.metadata.labels.env }}"
                operator: AnyNotIn
                value: "{{ split(allowed.data.values, ',') }}"
```
`split(allowed.data.values, ',')` turns the ConfigMap's comma-separated string into a list; `AnyNotIn` then denies whenever the Pod's `env` label value is not found in that list.

---

## Step 3: Apply the Policy

```bash
kubectl apply -f check-env-label.yaml
kubectl describe policy -n releases check-env-label | grep -A3 Status
```

---

## Step 4: Confirm the Disallowed Value Is Rejected

```bash
kubectl run bad-release --image=nginx -n releases --labels=env=qa --restart=Never
```
This is rejected with a message containing `env label 'qa' is not one of the allowed values: dev,staging,prod`.

---

## Step 5: Confirm an Allowed Value Is Accepted

```bash
kubectl run good-release --image=nginx -n releases --labels=env=staging --restart=Never
kubectl get pod -n releases good-release
```

Once verified, run the local validation suite to pass the lab!
