# Solution Walkthrough

The policy is a `Policy`, not a `ClusterPolicy`, so it lives in `storefront` and only sees objects there. You then prove it with one Service that is rejected and one that is admitted.

---

## Step 1: Write the policy

Save this as `deny-loadbalancer-services.yaml`:

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

The `!` in front of `LoadBalancer` is Kyverno's "not equal to" operator in a validate pattern. The rule passes only when `spec.type` is anything *other than* `LoadBalancer`.

---

## Step 2: Apply the policy

Apply it:

```bash
kubectl apply -f deny-loadbalancer-services.yaml
```

Then check that it is ready:

```bash
kubectl describe policy -n storefront deny-loadbalancer-services | grep -A3 Status
```

Look for a ready condition with status `True`.

---

## Step 3: Confirm the LoadBalancer Service is rejected

Save this as `service-checkout-lb.yaml`:

```yaml
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
```

Apply it:

```bash
kubectl apply -n storefront -f service-checkout-lb.yaml
```

The API server rejects it with an error containing `Service of type LoadBalancer is not allowed in the storefront namespace.` The Kyverno admission controller made that decision.

---

## Step 4: Confirm the ClusterIP Service is allowed

Save this as `service-checkout-clusterip.yaml`:

```yaml
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
```

Apply it:

```bash
kubectl apply -n storefront -f service-checkout-clusterip.yaml
```

Then check the result:

```bash
kubectl get svc -n storefront checkout-clusterip
```

The Service exists, with type `ClusterIP`.

---

## Step 5: Submit

```bash
astrona submit -c sections/section-020/module-01/labs/lab-01
```

---

## Common mistakes

* **Writing a `ClusterPolicy`.** The grader looks for a namespaced `Policy` in `storefront`.
* **Leaving out `metadata.namespace`.** The `Policy` lands in your default namespace and never sees `storefront`.
* **Using `Audit`.** Then `checkout-lb` is created and only reported, and the grader fails because it exists.
* **Forgetting `-n storefront` on the Service applies.** The Service files have no namespace, so without `-n` they land somewhere else.
