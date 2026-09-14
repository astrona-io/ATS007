# Solution Walkthrough

---

## Step 1: Write and Apply the Audit-Mode Policy

```yaml
# require-cost-center-label.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-cost-center-label
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-cost-center-label
      match:
        any:
          - resources:
              kinds:
                - Deployment
              namespaces:
                - analytics
      validate:
        message: "Deployments must carry a 'cost-center' label."
        pattern:
          metadata:
            labels:
              cost-center: "?*"
```

```bash
kubectl apply -f require-cost-center-label.yaml
```

---

## Step 2: Read the PolicyReport

Background scans run on an interval, so give it a few seconds, then check:

```bash
kubectl get policyreport -n analytics
kubectl get policyreport -n analytics -o json | jq '.items[].results[] | select(.result=="fail")'
```

Expect a `fail` entry naming `legacy-etl` and rule `check-cost-center-label`, proving the scan reached a Deployment that existed before the policy did.

---

## Step 3: Flip to Enforce

```bash
kubectl patch clusterpolicy require-cost-center-label \
  --type merge -p '{"spec":{"validationFailureAction":"Enforce"}}'
```

`legacy-etl` is **not** retroactively touched — flipping to Enforce does not delete, restart, or reject an already-existing resource; it only changes what happens to new admission requests going forward.

---

## Step 4: Confirm the New Block

```bash
kubectl create deployment legacy-etl-v2 --image=nginx -n analytics
```

Expect a rejection referencing the policy:

```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/analytics/legacy-etl-v2 was blocked due to the following policies

require-cost-center-label:
  check-cost-center-label: 'validation error: Deployments must carry a
    ''cost-center'' label. rule check-cost-center-label failed at path
    /metadata/labels/cost-center/'
```

`legacy-etl` continues running untouched; only the *new* Deployment request was rejected.
