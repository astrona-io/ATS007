# Solution Walkthrough

This capstone joins all three rule actions: a validate rule for the owner label, a mutate rule for the pull policy default, and a generate rule that clones the shared ConfigMap. Write each as its own policy, apply them, then prove each one.

---

## Step 1: Validate rule: require-owner-label

Save this as `require-owner-label.yaml`:

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

## Step 2: Mutate rule: default-image-pull-policy

A Pod can have several containers, so this mutate rule uses `foreach` to walk through them. `{{ element.name }}` is the name of the container in the current step, which tells the strategic merge which container to patch.

Save this as `default-image-pull-policy.yaml`:

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

Mutate rules run before validate rules, so this default is in place before `require-owner-label`, or the Kubernetes schema check, sees the object.

---

## Step 3: Generate rule: clone-shared-config

Save this as `clone-shared-config.yaml`:

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

## Step 4: Apply all three policies

Apply them:

```sh
kubectl apply -f require-owner-label.yaml
kubectl apply -f default-image-pull-policy.yaml
kubectl apply -f clone-shared-config.yaml
```

Then check the result:

```sh
kubectl get clusterpolicy
```

All three policies should be listed.

---

## Step 5: Confirm the Deployment path

A Deployment creates its Pods indirectly, so the mutate rule (which matches `Pod`) acts on the Pods the Deployment creates. This command builds the Deployment, adds the `owner` label, and applies it in one pipeline:

```sh
kubectl create deployment web --image=nginx:alpine -n checkout --dry-run=client -o yaml \
  | kubectl label --local -f - owner=checkout-team -o yaml \
  | kubectl apply -f -
kubectl get pod -n checkout -l app=web -o jsonpath='{.items[0].spec.containers[0].imagePullPolicy}'
```

The second command should print `IfNotPresent`, even though the Deployment you applied never set it. If it prints nothing, the Pod may not exist yet; wait a moment and run it again.

---

## Step 6: Confirm the clone

Create the new namespace, then look for the copied ConfigMap:

```sh
kubectl create namespace fulfillment
kubectl get configmap shared-app-config -n fulfillment
```

The ConfigMap exists without you creating it, cloned from `platform-shared` by the Kyverno background controller.

---

## Step 7: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

---

## Common mistakes

* **Naming the Deployment something other than `web`.** The grader looks for the Deployment `web` and its Pods with the label `app=web`.
* **Forgetting the `owner` label on the Deployment.** `require-owner-label` rejects it, and nothing is created.
* **Leaving out `synchronize: true`.** The grader checks for it on `clone-shared-config`.
* **Creating `fulfillment` before the generate policy exists.** The rule only reacts to new namespaces. Delete `fulfillment` and create it again.
