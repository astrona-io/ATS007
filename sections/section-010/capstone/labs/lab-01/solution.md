# Solution Walkthrough

Follow these steps to author, apply, and verify all three policies:

---

## Step 1: Validate Rule — require-owner-label
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-owner-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-owner-label
      match:
        any:
        - resources:
            kinds:
              - Deployment
            namespaces:
              - checkout
      validate:
        message: "A non-empty 'owner' label is required on every Deployment in checkout."
        pattern:
          metadata:
            labels:
              owner: "?*"
```

---

## Step 2: Mutate Rule — default-image-pull-policy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: default-image-pull-policy
spec:
  rules:
    - name: set-default-pull-policy
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - checkout
      mutate:
        foreach:
        - list: "request.object.spec.containers"
          patchStrategicMerge:
            spec:
              containers:
              - name: "{{ element.name }}"
                imagePullPolicy: IfNotPresent
```
Because `mutate` rules run before `validate` rules, this default is applied before `require-owner-label` (or Kubernetes' own object schema validation) ever sees the resource.

---

## Step 3: Generate Rule — clone-shared-config
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: clone-shared-config
spec:
  rules:
    - name: clone-config
      match:
        any:
        - resources:
            kinds:
              - Namespace
      generate:
        apiVersion: v1
        kind: ConfigMap
        name: shared-app-config
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        clone:
          namespace: platform-shared
          name: shared-app-config
```

---

## Step 4: Apply All Three Policies
```sh
kubectl apply -f require-owner-label.yaml
kubectl apply -f default-image-pull-policy.yaml
kubectl apply -f clone-shared-config.yaml
kubectl get clusterpolicy
```

---

## Step 5: Confirm the Deployment Path

Deployments create Pods indirectly, so the mutate rule (scoped to `Pod`) fires on the Pod template's realized Pods:
```sh
kubectl create deployment web --image=nginx:alpine -n checkout --dry-run=client -o yaml \
  | kubectl label --local -f - owner=checkout-team -o yaml \
  | kubectl apply -f -
kubectl get pod -n checkout -l app=web -o jsonpath='{.items[0].spec.containers[0].imagePullPolicy}'
```
Expect `IfNotPresent`, even though the Deployment manifest you applied never set it.

---

## Step 6: Confirm the Clone
```sh
kubectl create namespace fulfillment
kubectl get configmap shared-app-config -n fulfillment
```
Expect the ConfigMap to exist automatically, cloned from `platform-shared`.

---

## Step 7: Verify Your Configuration

Confirm all three policies are enforcing/generating as expected, then run the local validation suite to pass the lab!
