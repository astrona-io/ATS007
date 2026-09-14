# Solution Walkthrough

---

## Step 1: Author and Apply the Audit-Mode Policy

```yaml
# require-data-classification.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-data-classification
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-data-classification-label
      match:
        any:
          - resources:
              kinds:
                - Deployment
              namespaces:
                - payments
      validate:
        message: "Deployments in payments must carry a 'data-classification' label."
        pattern:
          metadata:
            labels:
              data-classification: "?*"
```

```bash
kubectl apply -f require-data-classification.yaml
```

---

## Step 2: Confirm the Webhook Rule

```bash
kubectl get validatingwebhookconfigurations kyverno-resource-validating-webhook-cfg -o json | grep -c '"deployments"'
```

Expect a count of at least `1` — Kyverno already tracks `Deployment` as a matched kind (possibly from other policies too), and your new policy keeps that entry in place.

---

## Step 3: Confirm the PolicyReport

```bash
kubectl get policyreport -n payments -o json | jq '.items[].results[] | select(.result=="fail")'
kubectl get deployment ledger-api -n payments -o jsonpath='{.metadata.labels}'
```

Expect a `fail` result naming `ledger-api` and rule `check-data-classification-label`, and an empty or unrelated labels map on `ledger-api` itself — proof it was reported on, not modified.

---

## Step 4: Flip to Enforce

```bash
kubectl patch clusterpolicy require-data-classification \
  --type merge -p '{"spec":{"validationFailureAction":"Enforce"}}'
```

---

## Step 5: Confirm Both Outcomes

```bash
kubectl create deployment ledger-api-v2 --image=nginx -n payments
```

Expect a rejection referencing `require-data-classification`.

```bash
kubectl create deployment ledger-api-v3 --image=nginx -n payments --dry-run=client -o yaml \
  | kubectl label -f - --local -o yaml data-classification=restricted \
  | kubectl apply -f -
kubectl get deployment ledger-api-v3 -n payments --show-labels
```

Expect `ledger-api-v3` to exist with `data-classification=restricted` in its labels, admitted without error.
