# Solution Walkthrough

Follow these steps to author, apply, and prove out the policy:

---

## Step 1: Write the ClusterPolicy

Create `require-team-label.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
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
              - payments
      exclude:
        any:
        - resources:
            namespaces:
              - kube-system
      validate:
        message: "A non-empty 'team' label is required on every Pod in payments."
        pattern:
          metadata:
            labels:
              team: "?*"
```
The `"?*"` pattern value requires at least one character — present and non-empty, not just present.

---

## Step 2: Apply the Policy
```sh
kubectl apply -f require-team-label.yaml
kubectl get clusterpolicy require-team-label
```
Confirm the `STATUS` (or equivalent readiness column, depending on Kyverno version) shows the policy as ready/validated.

---

## Step 3: Confirm the Block
```sh
kubectl run no-team-pod --image=nginx:alpine -n payments
```
Expect the API server to reject this with an admission error referencing your policy's `message`, similar to:
```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/payments/no-team-pod was blocked due to the following policies

require-team-label:
  check-team-label: 'validation error: A non-empty ''team'' label is required on every Pod in payments. rule check-team-label failed at path /metadata/labels/team/'
```

---

## Step 4: Confirm the Allow
```sh
kubectl run has-team-pod --image=nginx:alpine -n payments --labels="team=checkout"
kubectl get pod has-team-pod -n payments
```
This Pod satisfies the pattern and is admitted normally.

---

## Step 5: Verify Your Configuration

Confirm the policy exists, is scoped to `payments`, and excludes `kube-system`:
```sh
kubectl get clusterpolicy require-team-label -o yaml
```
Once verified, run the local validation suite to pass the lab!
