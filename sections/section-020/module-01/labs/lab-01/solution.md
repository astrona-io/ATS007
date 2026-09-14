# Solution Walkthrough

Follow these steps to author, apply, and verify the policy:

---

## Step 1: Author the Policy YAML

Create `deny-loadbalancer-services.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: deny-loadbalancer-services
  namespace: storefront
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: block-loadbalancer-type
      match:
        any:
          - resources:
              kinds:
                - Service
      validate:
        message: "Service of type LoadBalancer is not allowed in the storefront namespace."
        pattern:
          spec:
            type: "!LoadBalancer"
```
The `!` prefix on `LoadBalancer` in the pattern is Kyverno's "not equal to" operator for a validate pattern — the rule passes only when `spec.type` is anything *other than* `LoadBalancer`.

---

## Step 2: Apply the Policy

```bash
kubectl apply -f deny-loadbalancer-services.yaml
```
Confirm it is ready:
```bash
kubectl describe policy -n storefront deny-loadbalancer-services | grep -A3 Status
```

---

## Step 3: Confirm the LoadBalancer Service Is Rejected

```bash
kubectl apply -n storefront -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: checkout-lb
spec:
  type: LoadBalancer
  selector:
    app: checkout
  ports:
    - port: 80
EOF
```
This is rejected with an error containing `Service of type LoadBalancer is not allowed in the storefront namespace.`

---

## Step 4: Confirm the ClusterIP Service Is Allowed

```bash
kubectl apply -n storefront -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: checkout-clusterip
spec:
  type: ClusterIP
  selector:
    app: checkout
  ports:
    - port: 80
EOF
```
This succeeds:
```bash
kubectl get svc -n storefront checkout-clusterip
```

Once verified, run the local validation suite to pass the lab!
