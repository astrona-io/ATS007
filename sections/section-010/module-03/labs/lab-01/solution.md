# Solution Walkthrough

Follow these steps to write, apply, and verify both policies:

---

## Step 1: Write the Mutate Policy

Create `label-catalog-pods.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: label-catalog-pods
spec:
  rules:
    - name: add-managed-by-label
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - catalog
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              managed-by: kyverno
```

---

## Step 2: Write the Generate Policy

Create `default-deny-new-namespaces.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: default-deny-new-namespaces
spec:
  rules:
    - name: generate-default-deny
      match:
        any:
        - resources:
            kinds:
              - Namespace
      generate:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny-all
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
              - Egress
```

---

## Step 3: Apply Both Policies
```sh
kubectl apply -f label-catalog-pods.yaml
kubectl apply -f default-deny-new-namespaces.yaml
kubectl get clusterpolicy
```

---

## Step 4: Confirm the Mutation
```sh
kubectl run mutate-me --image=nginx:alpine -n catalog
kubectl get pod mutate-me -n catalog --show-labels
```
Expect `managed-by=kyverno` in the label list, even though it was never specified on the command line.

---

## Step 5: Confirm the Generation
```sh
kubectl create namespace orders
kubectl get networkpolicy default-deny-all -n orders -o yaml
```
Expect the `NetworkPolicy` to exist automatically, with `policyTypes: [Ingress, Egress]` and an empty `podSelector` (matching every Pod in the namespace).

---

## Step 6: Verify Your Configuration

Confirm both behaviors hold, then run the local validation suite to pass the lab!
