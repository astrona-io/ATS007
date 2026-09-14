# Solution Walkthrough

Follow these steps to write, apply, and verify the policy:

---

## Step 1: Confirm the Pre-existing Non-compliant Deployment
```sh
kubectl get deployment legacy-app -n storefront -o jsonpath='{.spec.template.spec.containers[0].resources}'
```
This should print an empty object `{}` — no requests or limits set.

---

## Step 2: Write the ClusterPolicy

Create `require-container-resources.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-container-resources
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-container-resources
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - storefront
      validate:
        message: "Every container must set CPU and memory requests and limits."
        foreach:
        - list: "request.object.spec.containers"
          pattern:
            resources:
              requests:
                cpu: "?*"
                memory: "?*"
              limits:
                cpu: "?*"
                memory: "?*"
```

---

## Step 3: Apply the Policy
```sh
kubectl apply -f require-container-resources.yaml
kubectl get clusterpolicy require-container-resources
```

---

## Step 4: Confirm Admission-Time Enforcement
```sh
kubectl run bad-pod --image=nginx:alpine -n storefront
```
Expect this to be rejected, with the error naming the `check-container-resources` rule.

---

## Step 5: Confirm Background Scanning Caught legacy-app

Background scans run on an interval, so allow it a short moment, then check:
```sh
kubectl get policyreport -n storefront -o wide
```
Expect a `PolicyReport` entry referencing `legacy-app` with a `fail` (or `warn`) result for `require-container-resources`, while:
```sh
kubectl get deployment legacy-app -n storefront
```
still shows it running, completely untouched — background scanning under `Audit`-style reporting never deletes or blocks existing resources; it only records the finding.

---

## Step 6: Verify Your Configuration

Confirm both the block and the report exist as expected before running the local validation suite to pass the lab!
