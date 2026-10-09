# Solution Walkthrough

You need two separate policies: a mutate rule that adjusts Pods on their way into `catalog`, and a generate rule that builds a `NetworkPolicy` on every new namespace.

---

## Step 1: Write the mutate policy

The `patchStrategicMerge` overlay is shaped like the Pod's own `metadata`, so Kubernetes merges the label in next to any labels already there.

Save this as `label-catalog-pods.yaml`:

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

## Step 2: Write the generate policy

The trigger is any new `Namespace`. The variable `{{request.object.metadata.name}}` puts the generated `NetworkPolicy` inside that new namespace.

Save this as `default-deny-new-namespaces.yaml`:

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

## Step 3: Apply both policies

Apply them:

```sh
kubectl apply -f label-catalog-pods.yaml
kubectl apply -f default-deny-new-namespaces.yaml
```

Then check the result:

```sh
kubectl get clusterpolicy
```

Both policies should be listed.

---

## Step 4: Confirm the mutation

Create a Pod with no labels of your own, then show its labels:

```sh
kubectl run mutate-me --image=nginx:alpine -n catalog
kubectl get pod mutate-me -n catalog --show-labels
```

Look for `managed-by=kyverno` in the label list, even though the command never mentioned it. The Kyverno admission controller added it before the Pod was stored.

---

## Step 5: Confirm the generation

Create the new namespace, then look for the generated `NetworkPolicy`:

```sh
kubectl create namespace orders
kubectl get networkpolicy default-deny-all -n orders -o yaml
```

The `NetworkPolicy` exists without you creating it, with `policyTypes` `Ingress` and `Egress` and an empty `podSelector` (which selects every Pod in the namespace). The background controller creates it, so if it is not there yet, wait a moment and run the second command again.

---

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

---

## Common mistakes

* **Putting both rules in one rule entry.** A rule has exactly one action. Mutate and generate are two rules, here in two policies.
* **Testing the mutation on an existing Pod.** Only Pods created after the policy get the label. The grader looks at a Pod named `mutate-me`.
* **Hard-coding the namespace in the generate rule.** Use `{{request.object.metadata.name}}`, or every copy lands in the same place.
* **Creating `orders` before the generate policy exists.** A generate rule only reacts to namespaces created after it. If you did, delete `orders` and create it again.
