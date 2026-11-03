# Solution Walkthrough

This mission has two halves. Admission must block new failing Pods, and the background scan must report the old Deployment that was already flying before the policy existed.

---

## Step 1: Confirm the existing non-compliant Deployment

Look at the resources of the first container in `legacy-app`:

```sh
kubectl get deployment legacy-app -n storefront -o jsonpath='{.spec.template.spec.containers[0].resources}'
```

This should print an empty object, `{}`: no requests or limits are set.

---

## Step 2: Write the ClusterPolicy

The `foreach` walks through every container in the incoming Pod and checks each one against the pattern.

Save this as `require-container-resources.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-container-resources
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-container-resources
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - storefront
      validate:
        message: "Every container must set CPU and memory requests and limits."
        foreach:
        - list: "request.object.spec.containers"
          pattern:
            resources:
              requests:
                cpu: "?*"
                memory: "?*"
              limits:
                cpu: "?*"
                memory: "?*"
```

The rule matches `Pod`, but Kyverno also applies Pod rules to the Pod template inside a Deployment. That is how the background scan can report on `legacy-app` itself.

---

## Step 3: Apply the policy

Apply it:

```sh
kubectl apply -f require-container-resources.yaml
```

Then check the result:

```sh
kubectl get clusterpolicy require-container-resources
```

---

## Step 4: Confirm admission-time enforcement

Try to launch a Pod with no resources:

```sh
kubectl run bad-pod --image=nginx:alpine -n storefront
```

This is rejected, and the error names the `check-container-resources` rule.

---

## Step 5: Confirm the background scan caught legacy-app

Background scans and reports take a little time. Wait a moment, then read the inspection log for `storefront`:

```sh
kubectl get policyreport -n storefront -o wide
```

Look for a `PolicyReport` entry that refers to `legacy-app` with a `fail` (or `warn`) result for `require-container-resources`. If nothing is there yet, wait and run the command again. Then check the Deployment itself:

```sh
kubectl get deployment legacy-app -n storefront
```

It is still running, untouched. A background scan never deletes or blocks existing objects; it only records the finding.

---

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

---

## Common mistakes

* **Checking only `containers[0]`.** The grader looks for a `foreach` block in the policy.
* **Setting `background: false`.** Then nothing scans `legacy-app`, and no report mentions it.
* **"Fixing" `legacy-app`.** The task is to report it, not to change or delete it. The grader needs it to still exist.
* **Submitting before the report exists.** The grader waits up to two minutes, but check the report yourself first.
