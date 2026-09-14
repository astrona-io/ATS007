# Solution Walkthrough

Follow these steps to build, apply, and verify the capstone policy:

---

## Step 1: Confirm the Namespace Label

```bash
kubectl get namespace payments --show-labels
```
Confirm it shows `cost-center=cc-4471`.

---

## Step 2: Author the Policy YAML

Create `require-matching-cost-center.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: require-matching-cost-center
  namespace: payments
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: cost-center-must-match-namespace
      match:
        any:
          - resources:
              kinds:
                - Pod
      context:
        - name: nsInfo
          apiCall:
            urlPath: "/api/v1/namespaces/payments"
            jmesPath: "metadata.labels.\"cost-center\""
      validate:
        message: "Pod cost-center '{{ request.object.metadata.labels.\"cost-center\" }}' does not match namespace cost-center '{{ nsInfo }}'."
        deny:
          conditions:
            all:
              - key: "{{ request.object.metadata.labels.\"cost-center\" }}"
                operator: NotEquals
                value: "{{ nsInfo }}"
```
The `apiCall` fetches the live `payments` Namespace object and reduces it with `jmesPath` straight down to the `cost-center` label value, bound to `nsInfo`. The `deny.conditions` block then compares the Pod's own label against that fetched value.

---

## Step 3: Apply the Policy

```bash
kubectl apply -f require-matching-cost-center.yaml
kubectl describe policy -n payments require-matching-cost-center | grep -A3 Status
```

---

## Step 4: Confirm the Mismatched Pod Is Rejected

```bash
kubectl run mismatched-billing --image=nginx -n payments --labels=cost-center=cc-9999 --restart=Never
```
This is rejected with a message containing both `cc-9999` and `cc-4471`.

---

## Step 5: Confirm the Matching Pod Is Accepted

```bash
kubectl run matched-billing --image=nginx -n payments --labels=cost-center=cc-4471 --restart=Never
kubectl get pod -n payments matched-billing
```

Once verified, run the local validation suite to pass the lab!
