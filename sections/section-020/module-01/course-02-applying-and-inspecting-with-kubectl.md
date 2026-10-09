# Applying & Inspecting with kubectl

Astronaut, once a Kyverno policy is just another manifest, every `kubectl` habit you already have works on it unchanged. This part shows which components act on a policy once it exists, how to apply one, and how to confirm it is really active.

## Who enforces the manifest you apply

Registering the policy kinds taught the API server what a policy *looks like*. Something still has to act on one. That something is a set of ordinary Deployments in the `kyverno` namespace. So you check Kyverno's own health with exactly the commands you would use for any other workload, and you troubleshoot an unhealthy controller the same way.

<!-- astrona:playground:renew -->

### See the controllers in your playground

List the Deployments in the `kyverno` namespace:

```sh
kubectl -n kyverno get deployments
```

You should see something like:

```text
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
kyverno-admission-controller    1/1     1            1           3m
kyverno-background-controller   1/1     1            1           3m
kyverno-cleanup-controller      1/1     1            1           3m
kyverno-reports-controller      1/1     1            1           3m
```

Names and ages change with the release and with how long the playground has been up. Each controller has a different job. The admission controller is the inspector at the launch gate: it answers the API server during a live request. That is why a policy stops being enforced the moment that Deployment is unavailable.

## The blank slate you start from

Registered kinds and running controllers still do not mean any rule is active. A freshly installed Kyverno enforces nothing, because no policy objects exist yet. See that empty state once. Later, when an object is unexpectedly rejected, your first question will be *which policy did that*, not whether Kyverno is broken.

### Confirm nothing is enforced yet

List both policy kinds:

```sh
kubectl get clusterpolicy
kubectl get policy --all-namespaces
```

You should see something like:

```text
No resources found
No resources found
```

Both kinds can be queried, because they are registered, but the cluster holds no rules, so every request is admitted. This is your starting point. (On Kyverno v1.19 each of these commands also prints a `Warning: kyverno.io/v1 ... is deprecated` line from the API server. It is expected and not an error; the course teaches these kinds because the exam does.)

## Applying a policy

The commands below need the file `require-team-label.yaml` in your current folder. It holds the `require-team-label` `ClusterPolicy`: an `Enforce` policy whose rule `check-team-label` requires a non-empty `team` label on every Pod, with the message `A 'team' label is required on every Pod.`

Applying it works exactly like applying a Deployment:

```sh
kubectl apply -f require-team-label.yaml
```

The object is created or updated, and `kubectl` prints `clusterpolicy.kyverno.io/require-team-label created`. Nothing is compiled or loaded into an engine as a separate step. The Kyverno admission controller watches `ClusterPolicy` and `Policy` objects with the normal Kubernetes watch mechanism. The moment the object is stored in etcd, the controller picks it up and starts enforcing it, usually within a second or two.

## Confirming a policy is active

Creating the object is not the same as Kyverno accepting it and enforcing it. Three commands close that gap. `kubectl get` and `kubectl describe` show the policy and its status:

```sh
kubectl get clusterpolicy
kubectl describe clusterpolicy require-team-label
```

`kubectl describe` prints the policy's `Status` section. It includes a ready condition, which means Kyverno has checked that the policy's own rules are well formed. Once background scanning has run, it also shows counts of passing and failing objects. A policy stuck at not ready almost always has a rule that names a `kind` the API server does not know (a typo, or a CRD that is not installed), and `kubectl describe` prints the exact error.

Kubernetes events show rejections at admission:

```sh
kubectl get events --field-selector reason=PolicyViolation -A
```

This is often the fastest way to see *why* a `kubectl apply` on some unrelated object just failed, without finding and reading a `PolicyReport`.

### Apply, confirm ready, then read a rejection

Put the three steps together: apply the policy, check its status, and try to launch a Pod with no `team` label:

```sh
kubectl apply -f require-team-label.yaml
kubectl describe clusterpolicy require-team-label | grep -A3 Status
kubectl run no-label --image=nginx --restart=Never
```

You should see something like:

```text
clusterpolicy.kyverno.io/require-team-label created

Status:
  Conditions:
    Message:  Ready
    Reason:   Succeeded
    Status:   True
    Type:     Ready

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/no-label was blocked due to the following policies

require-team-label:
  check-team-label: 'validation error: A ''team'' label is required on every Pod. rule check-team-label failed at path /metadata/labels/team/'
```

The rejection message is exactly the `validate.message` text in the policy. That is how a blocked request tells the person who sent it precisely what to fix. If you applied the policy before, the first line says `unchanged` instead of `created`.

This policy matches every Pod in the cluster, including system Pods. When you have finished experimenting, remove it with `kubectl delete clusterpolicy require-team-label`.

## Common pitfalls

> [!WARNING]
> - **Treating "created" as "enforced".** `kubectl apply` only stores the object. Check the ready condition with `kubectl describe` before you trust the policy.
> - **Suspecting Kyverno when a policy is not ready.** A policy that never becomes ready usually names a kind the cluster does not know. Read the error in `kubectl describe`.
> - **Forgetting the admission controller is a normal Deployment.** If `kyverno-admission-controller` is not ready, no policy is enforced. Check it with `kubectl -n kyverno get deployments`.
> - **Leaving a broad `Enforce` policy behind.** A test policy that matches every Pod keeps blocking Pods, including system ones. Delete it when you are done.

> *`kubectl apply` puts the policy in etcd exactly like any manifest, and `describe` and `get events` are how you confirm what happened next.*
