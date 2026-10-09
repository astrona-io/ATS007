# Solution Walkthrough

The rule loads the allow-list from the ConfigMap with a `context` entry, turns the comma-separated string into a list with `split`, and denies any Pod whose `env` label is not in it.

---

## Step 1: Inspect the existing ConfigMap

Read the notice board first:

```bash
kubectl get configmap allowed-environments -n releases -o yaml
```

Check that it holds `data.values: dev,staging,prod`.

---

## Step 2: Write the policy

Save this as `check-env-label.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: check-env-label
  namespace: releases
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: env-must-be-allowed
      match:
        any:
          - resources:
              kinds:
                - Pod
      context:
        - name: allowed
          configMap:
            name: allowed-environments
            namespace: releases
      validate:
        message: "env label '{{ request.object.metadata.labels.env }}' is not one of the allowed values: {{ allowed.data.values }}"
        deny:
          conditions:
            all:
              - key: "{{ request.object.metadata.labels.env }}"
                operator: AnyNotIn
                value: "{{ split(allowed.data.values, ',') }}"
```

`split(allowed.data.values, ',')` turns the ConfigMap's comma-separated string into a list. `AnyNotIn` then denies whenever the Pod's `env` label value is not in that list.

---

## Step 3: Apply the policy

Apply it:

```bash
kubectl apply -f check-env-label.yaml
```

Then check that it is ready:

```bash
kubectl describe policy -n releases check-env-label | grep -A3 Status
```

---

## Step 4: Confirm the disallowed value is rejected

Launch a Pod with an environment that is not on the list:

```bash
kubectl run bad-release --image=nginx -n releases --labels=env=qa --restart=Never
```

This is rejected with a message containing `env label 'qa' is not one of the allowed values: dev,staging,prod`. The same policy, tried with a Pod named `bad-env`, gave this full rejection:

```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

check-env-label:
  env-must-be-allowed: 'validation error: env label ''qa'' is not one of the allowed values: dev,staging,prod. rule env-must-be-allowed failed...'
```

Both the refused value and the allowed list came from variables. The ConfigMap, not the policy YAML, decides what is allowed.

---

## Step 5: Confirm an allowed value is accepted

Launch a Pod with an allowed environment:

```bash
kubectl run good-release --image=nginx -n releases --labels=env=staging --restart=Never
kubectl get pod -n releases good-release
```

The Pod exists.

---

## Step 6: Submit

```bash
astrona submit -c sections/section-020/module-02/labs/lab-01
```

---

## Common mistakes

* **Comparing with the raw string.** `dev,staging,prod` is one string; without `split`, the check does not work as a list check.
* **Putting the `context` entry in the wrong place.** The grader reads `spec.rules[0].context[0].configMap.name`, so the ConfigMap must be the first `context` entry of the first rule.
* **A message without the value.** The task asks for the refused `env` value in the message; use `{{ request.object.metadata.labels.env }}`.
* **Writing a `ClusterPolicy`.** The task asks for a namespaced `Policy` in `releases`.
