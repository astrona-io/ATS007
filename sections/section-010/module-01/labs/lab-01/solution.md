# Solution Walkthrough

The mission has three moves: write the rule book, apply it, then prove it with one Pod that is rejected and one that is admitted.

---

## Step 1: Write the ClusterPolicy

The rule must look only at Pods in `payments` (the `match` block) and wave `kube-system` past (the `exclude` block). The `validate` pattern then demands a `team` label.

Save this as `require-team-label.yaml`:

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

The pattern value `"?*"` needs at least one character. So the label must be present *and* non-empty, not just present.

---

## Step 2: Apply the policy

Apply it:

```sh
kubectl apply -f require-team-label.yaml
```

Then check the result:

```sh
kubectl get clusterpolicy require-team-label
```

Look for the policy's ready column (its name depends on the Kyverno version) to show that the policy is ready. A `Warning: kyverno.io/v1 ClusterPolicy is deprecated` line on these commands is expected and not an error.

---

## Step 3: Confirm the block

Try to launch a Pod without the label:

```sh
kubectl run no-team-pod --image=nginx:alpine -n payments
```

The API server rejects it with an admission error that quotes your policy's `message`, similar to:

```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/payments/no-team-pod was blocked due to the following policies

require-team-label:
  check-team-label: 'validation error: A non-empty ''team'' label is required on every Pod in payments. rule check-team-label failed at path /metadata/labels/team/'
```

The error names the webhook (`validate.kyverno.svc-fail`), the policy, the rule and the path that failed. The Kyverno admission controller made this decision; the API server only passed on its answer.

---

## Step 4: Confirm the allow

Launch a Pod that carries the label:

```sh
kubectl run has-team-pod --image=nginx:alpine -n payments --labels="team=checkout"
kubectl get pod has-team-pod -n payments
```

This Pod fits the pattern, so it is admitted normally.

---

## Step 5: Check your configuration

Read the whole policy back and check that it is scoped to `payments`, excludes `kube-system` and uses `Enforce`:

```sh
kubectl get clusterpolicy require-team-label -o yaml
```

---

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

---

## Common mistakes

* **Using `"*"` instead of `"?*"`.** `"*"` also accepts an empty label value; `"?*"` needs at least one character.
* **Forgetting the `exclude` block.** The grader checks that the policy mentions `kube-system`.
* **Leaving the policy in `Audit`.** Then `no-team-pod` is created and only reported, and the grader fails because the Pod exists.
* **Creating `no-team-pod` before the policy is ready.** If the Pod slipped in before the policy was active, delete it and try again.
